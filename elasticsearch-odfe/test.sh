if [ -z "$ES_TMPDIR" ]; then
  set +e
  mktemp --version 2>&1 | grep 'coreutils\|busybox'
  mktemp_coreutils=$?
  echo $mktemp_coreutils
  set -e
  if [ $mktemp_coreutils -eq 0 ]; then
    ES_TMPDIR=`mktemp -d --tmpdir "elasticsearch.XXXXXXXX"`
  else
    ES_TMPDIR=`mktemp -d -t elasticsearch`
  fi
fi
