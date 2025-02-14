CWD="$(dirname "$0")"
# BASE_BENCHMARKS_FOLDER="${CWD}/benchmarks"
BASE_SUT_FOLDER="${CWD}/sut"
BASE_DRIVERS_FOLDER="${CWD}/drivers"

help() {
  echo "Usage: $0 [sut|help] [driver] [additional_params]"
  echo ""
  echo "Examples:"
  echo "  Print this help message"
  echo "    $0 [help|--help|-h]"
  echo "  Pause the server during the test"
  echo "    $0 sut k6 \"-S SUT_PAUSE_BEFORE_DURATION=20 -S SUT_PAUSE_DURATION=3\""
  echo "  Increase the test duration"
  echo "    $0 sut jmeter \"-S DURATION=60\""
}

if [[ $# -ge 1 && ( "$1" == "help" || "$1" == "-h" || "$1" == "--help" ) ]]; then
  help
  exit 0
fi

# Check if the correct number of arguments is provided
if [ "$#" -gt 3 ]; then
  help
  exit 1
fi

# Validate driver
if [ "$#" -ge 1 ]; then
  SUT="$1"
  if [ ! -f "$BASE_SUT_FOLDER/$SUT.yaml" ]; then
    echo "Error: SUT script file '$SUT.yaml' does not exist in $BASE_SUT_FOLDER."
    echo "Available SUTs are:"
    ls -1 $BASE_SUT_FOLDER/*.yaml
    exit 1
  fi
else
  # default is 'sut' 
  SUT="sut"
fi

# Validate driver
if [ "$#" -ge 2 ]; then
  DRIVER="$2"
  if [ ! -f "$BASE_DRIVERS_FOLDER/$DRIVER.yaml" ]; then
    echo "Error: Driver script file '$DRIVER.yaml' does not exist in $BASE_DRIVERS_FOLDER."
    echo "Available drivers are:"
    ls -1 $BASE_DRIVERS_FOLDER/*.yaml
    exit 1
  fi
else
  # default is 'hf-wrk2' hf wrapper 
  DRIVER="hf-wrk2"
fi

# handle additional HF benchmark params
if [ "$#" -eq 3 ]; then
  ADDITIONAL_ARGS="$3"
else
  ADDITIONAL_ARGS=""
fi

QDUP_CMD="jbang qDup@hyperfoil $ADDITIONAL_ARGS sut/${SUT}.yaml drivers/${DRIVER}.yaml util.yaml qdup.yaml"

echo Executing: "$QDUP_CMD"

eval $QDUP_CMD