#!/bin/bash

#---------------------------------------------------------------------------------------#
# Script Name   : explain_sql_query.sh
# Description   : Get execution plan for a MariaDB SQL query, save to a file, and email it
# Requires: mysql CLI, and either mailx/mail/sendmail for email
# Created By    : Arnold Aristotle Tayag
# Created On    : 01-AUG-2021
#---------------------------------------------------------------------------------------#


# -------- Change based on environment --------
HOST="192.168.1.1"
USER=""
DB=""
SOCKET=""


# -------- Defaults --------
PORT="3306"
OUTDIR="."
RECIPIENT="aamtayag@uob.com"
SUBJECT_PREFIX="[MariaDB EXPLAIN]"
QUERY=""
QUERY_FILE=""
ASK_PASS=0
FORMAT_JSON_TRY=1     # try EXPLAIN FORMAT=JSON first
ATTACH=1              # attach results if mailx supports -a

usage() {
  cat <<'USAGE'
  Usage:
    explain_sql_query.sh -u USER -d DB [-h HOST] [-P PORT] [-S SOCKET] [-o OUTDIR]
                         (-q "SELECT ...;" | -f query.sql)
                         -r recipient@example.com
                         [-p] [--no-json] [--no-attach]

  Options:
    -u USER          Database user.
    -d DB            Database/schema name.
    -h HOST          Host (default: 127.0.0.1).
    -P PORT          Port (default: 3306).
    -S SOCKET        UNIX socket path (overrides host/port if set).
    -o OUTDIR        Output directory for results (default: current dir).
    -q "SQL"         Inline SQL to explain (surround with quotes).
    -f FILE.sql      Path to a SQL file containing a single statement to explain.
    -r EMAIL         Recipient email address for the results.
    -p               Prompt for DB password (or set MYSQL_PWD env / use ~/.my.cnf).
    --no-json        Do not attempt EXPLAIN FORMAT=JSON (use classic EXPLAIN only).
    --no-attach      Put results inline in email body (don’t attach file).
    -h/--help        Show this help.

  Notes:
  - Password order of precedence: prompt (-p) > MYSQL_PWD env > ~/.my.cnf
  - Script attempts JSON explain and falls back to classic EXPLAIN if unsupported.
  USAGE
}

# -------- Parse Args --------
while (( "$#" )); do
  case "$1" in
    -u) USER="$2"; shift 2;;
    -d) DB="$2"; shift 2;;
    -h) HOST="$2"; shift 2;;
    -P) PORT="$2"; shift 2;;
    -S) SOCKET="$2"; shift 2;;
    -o) OUTDIR="$2"; shift 2;;
    -q) QUERY="$2"; shift 2;;
    -f) QUERY_FILE="$2"; shift 2;;
    -r) RECIPIENT="$2"; shift 2;;
    -p) ASK_PASS=1; shift;;
    --no-json) FORMAT_JSON_TRY=0; shift;;
    --no-attach) ATTACH=0; shift;;
    --help|-help|-h|help) usage; exit 0;;
    *) echo "Unknown arg: $1"; usage; exit 1;;
  esac
done

# -------- Validate --------
if [[ -z "$USER" || -z "$DB" || -z "$RECIPIENT" ]]; then
  echo "Error: -u, -d, and -r are required." >&2
  usage; exit 1
fi

if [[ -z "$QUERY" && -z "$QUERY_FILE" ]]; then
  echo "Error: Provide -q \"SQL\" or -f FILE.sql" >&2
  usage; exit 1
fi

if [[ -n "$QUERY_FILE" && ! -f "$QUERY_FILE" ]]; then
  echo "Error: SQL file '$QUERY_FILE' not found." >&2
  exit 1
fi

mkdir -p "$OUTDIR"

# -------- Password Handling --------
PASS_OPTS=()
if (( ASK_PASS == 1 )); then
  # Prompt safely (no echo)
  read -r -s -p "Enter password for user '$USER': " DBPASS
  echo
  PASS_OPTS+=( "-p${DBPASS}" )
else
  # Use MYSQL_PWD if present; otherwise rely on ~/.my.cnf or no password
  if [[ -n "${MYSQL_PWD:-}" ]]; then
    PASS_OPTS+=( "-p${MYSQL_PWD}" )
  fi
fi

# -------- Build mysql CLI Options --------
MYSQL_OPTS=( "--batch" "--raw" "--silent" "-u" "$USER" "-D" "$DB" )
if [[ -n "$SOCKET" ]]; then
  MYSQL_OPTS+=( "--socket=$SOCKET" )
else
  MYSQL_OPTS+=( "-h" "$HOST" "-P" "$PORT" )
fi
MYSQL_OPTS+=( "${PASS_OPTS[@]}" )

# -------- Prepare SQL --------
if [[ -n "$QUERY_FILE" ]]; then
  SQL_STMT="$(<"$QUERY_FILE")"
else
  SQL_STMT="$QUERY"
fi

# Trim trailing semicolon/newlines
SQL_STMT="$(printf "%s" "$SQL_STMT" | awk 'BEGIN{RS="";} {gsub(/^[[:space:]]+|[[:space:]]+$/,""); print}' )"
SQL_STMT="${SQL_STMT%;}"

# -------- Output File --------
TS="$(date +%Y%m%d_%H%M%S)"
BASENAME="explain_${DB}_${TS}"
OUTFILE="${OUTDIR%/}/${BASENAME}.txt"

# -------- Run EXPLAIN --------
{
  echo "===== MariaDB EXPLAIN Report ====="
  echo "Database : $DB"
  if [[ -n "$SOCKET" ]]; then
    echo "Socket   : $SOCKET"
  else
    echo "Host     : $HOST"
    echo "Port     : $PORT"
  fi
  echo "User     : $USER"
  echo "Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
  echo
  echo "---- Original SQL ----"
  echo "$SQL_STMT;"
  echo

  if (( FORMAT_JSON_TRY == 1 )); then
    echo "---- EXPLAIN FORMAT=JSON ----"
    # Try JSON; on failure print message and continue
    if ! mysql "${MYSQL_OPTS[@]}" -e "EXPLAIN FORMAT=JSON ${SQL_STMT};" 2> >(sed 's/^/ERROR: /' >&2); then
      echo "[Info] FORMAT=JSON not supported or failed; falling back to classic EXPLAIN."
      echo
      echo "---- Classic EXPLAIN ----"
      mysql "${MYSQL_OPTS[@]}" -e "EXPLAIN ${SQL_STMT};"
    fi
  else
    echo "---- Classic EXPLAIN ----"
    mysql "${MYSQL_OPTS[@]}" -e "EXPLAIN ${SQL_STMT};"
  fi

  echo
  echo "---- SHOW WARNINGS (if any) ----"
  mysql "${MYSQL_OPTS[@]}" -e "SHOW WARNINGS;" || true

} | tee "$OUTFILE" >/dev/null

# -------- Email Sending --------
SUBJECT="${SUBJECT_PREFIX} ${DB} plan @ ${TS}"
BODY_INTRO=$(
cat <<EOF
MariaDB EXPLAIN report generated.

Database : ${DB}
User     : ${USER}
When     : $(date -u '+%Y-%m-%d %H:%M:%S UTC')
File     : ${OUTFILE}

Original SQL:
${SQL_STMT};

EOF
)

send_with_mailx() {
  if command -v mailx >/dev/null 2>&1; then
    if (( ATTACH == 1 )); then
      mailx -s "$SUBJECT" -a "$OUTFILE" "$RECIPIENT" <<< "$BODY_INTRO"
    else
      mailx -s "$SUBJECT" "$RECIPIENT" <<< "$BODY_INTRO$(printf '\n==== Report ====\n'); cat "$OUTFILE" | mailx -s "$SUBJECT" "$RECIPIENT"
    fi
    return 0
  fi
  return 1
}

send_with_mail() {
  if command -v mail >/dev/null 2>&1; then
    if (( ATTACH == 1 )); then
      # Basic mail has no portable attachment flag; inline content instead.
      mail -s "$SUBJECT" "$RECIPIENT" < "$OUTFILE"
    else
      mail -s "$SUBJECT" "$RECIPIENT" <<< "$BODY_INTRO$(printf '\n==== Report ====\n'; cat "$OUTFILE")"
    fi
    return 0
  fi
  return 1
}

send_with_sendmail() {
  if command -v sendmail >/dev/null 2>&1; then
    {
      echo "To: $RECIPIENT"
      echo "Subject: $SUBJECT"
      echo "MIME-Version: 1.0"
      BOUNDARY="=====BOUNDARY_$$"
      echo "Content-Type: multipart/mixed; boundary=\"$BOUNDARY\""
      echo
      echo "--$BOUNDARY"
      echo "Content-Type: text/plain; charset=UTF-8"
      echo "Content-Transfer-Encoding: 8bit"
      echo
      echo "$BODY_INTRO"
      echo
      echo "--$BOUNDARY"
      echo "Content-Type: text/plain; name=\"$(basename "$OUTFILE")\""
      echo "Content-Disposition: attachment; filename=\"$(basename "$OUTFILE")\""
      echo "Content-Transfer-Encoding: base64"
      echo
      base64 "$OUTFILE"
      echo "--$BOUNDARY--"
    } | sendmail -t
    return 0
  fi
  return 1
}

if send_with_mailx || send_with_mail || send_with_sendmail; then
  echo "Report saved to: $OUTFILE"
  echo "Email sent to:   $RECIPIENT"
else
  echo "Warning: No mailer found (mailx/mail/sendmail). Report saved to: $OUTFILE" >&2
  exit 2
fi
