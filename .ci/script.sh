#!/usr/bin/env bash

# vim :set ts=2 sw=2 sts=2 et:
echo "which java: $(which java)"
echo "java_home: $(command -v "/usr/libexec/java_home")"
./gradlew --version
ulimit -c unlimited -S
if [ "$TRAVIS_JDK_VERSION" == "oraclejdk9" ]; then
  ./gradlew build --debug --stacktrace
else
  ./gradlew build --info
fi
RESULT=$?
if [[ ${RESULT} -ne 0 ]]; then
  JVMCRASH="$(find . -name "hs_err_pid*.log" -type f -print | head -n 1)"
  if [ -f "$JVMCRASH" ]; then
    echo "======= JVM Crash Log $JVMCRASH ======="
    cat "$JVMCRASH"
  fi

  CORES=''
  if [[ "${TRAVIS_OS_NAME}" == osx ]]; then
    CORES="$(find /cores/ -type f -print)"
  else
    CORES="$(find . -type f -name 'core.*' -print)"
  fi

  if [ -n "${CORES}" ]; then
    for core in ${CORES}; do
    echo "======= Core file $core ======="
    if [[ "${TRAVIS_OS_NAME}" == osx ]]; then
      lldb -Q -o "bt all" -f "$(which java)" -c "${core}"
    else
      gdb -n -batch -ex "thread apply all bt" -ex "set pagination 0" "$(which java)" -c "${core}"
    fi
  done
  fi

  exit ${RESULT}
fi
