#!/bin/bash

# set -x trace
CURRENT_DIR=$(dirname $0)

###################################
#### overridable configuration ####
###################################

TEST_CASE=${TEST_CASE:-"simple_request_300_rps"}

THREADS=${THREADS:-10}

WARMUP_BEFORE_PAUSE=${WARMUP_BEFORE_PAUSE:-20}
SERVER_PAUSE_DURATION=${SERVER_PAUSE_DURATION:-7}

HYPERFOIL_HOME=${HYPERFOIL_HOME:-$CURRENT_DIR/hyperfoil}
K6=${K6:-"k6"}
JMETER=${JMETER:-"jmeter"}
HF=${HF:-"$HYPERFOIL_HOME/bin/wrk2.sh"}
ARTILLERY=${ARTILLERY:-"artillery"}

HF_ENABLED=${HF_ENABLED:-"true"}
JMETER_ENABLED=${JMETER_ENABLED:-"true"}
K6_ENABLED=${K6_ENABLED:-"true"}
ARTILLERY_ENABLED=${ARTILLERY_ENABLED:-"true"}

###################################
########## core logic #############
###################################


TEST_CASE_FOLDER="$CURRENT_DIR/../$TEST_CASE"

# create the results folder
TEST_CASE_RESULTS_FOLDER="$CURRENT_DIR/../results/$TEST_CASE/$(date '+%d%m%Y_%H%M%S')/"
mkdir -p "$TEST_CASE_RESULTS_FOLDER"

java -Dquarkus.vertx.event-loops-pool-size=${THREADS} -XX:+UnlockDiagnosticVMOptions -XX:+DebugNonSafepoints -jar $CURRENT_DIR/../quarkus-profiling-workshop/target/quarkus-app/quarkus-run.jar &
quarkus_pid=$!

trap "echo 'cleaning up quarkus process';kill ${quarkus_pid}" SIGINT SIGTERM SIGKILL

sleep 2

echo "----- Start test $(basename ${TEST_CASE_FOLDER})"

echo "----- Server started with pid ${quarkus_pid}"

# hyperfoil
if [ "$HF_ENABLED" = "true" ]; then
    mkdir -p "$TEST_CASE_RESULTS_FOLDER/hyperfoil"
    source $TEST_CASE_FOLDER/hf-config.env
    ${HF} -R ${RATE} -c ${CONNECTIONS} -t ${THREADS} -d ${DURATION}s --latency ${FULL_URL} &> "$TEST_CASE_RESULTS_FOLDER/hyperfoil/hf.log" &
    wrk_pid=$!
fi

# jmeter
if [ "$JMETER_ENABLED" = "true" ]; then
    mkdir -p "$TEST_CASE_RESULTS_FOLDER/jmeter"
    ${JMETER} -n -t $TEST_CASE_FOLDER/jmeter-config.jmx -l $TEST_CASE_RESULTS_FOLDER/jmeter/log.jtl -j $TEST_CASE_RESULTS_FOLDER/jmeter/jmeter.log -e -o $TEST_CASE_RESULTS_FOLDER/jmeter/jmeter-report -f >/dev/null &
    jmeter_pid=$!
fi

# k6
if [ "$K6_ENABLED" = "true" ]; then
    mkdir -p "$TEST_CASE_RESULTS_FOLDER/k6"
    ${K6} run --summary-trend-stats="avg,min,med,max,p(50),p(75),p(90),p(99),p(99.9),p(99.99),p(99.999),count" --out json=$TEST_CASE_RESULTS_FOLDER/k6/k6-output.json $TEST_CASE_FOLDER/k6-config.js &> "$TEST_CASE_RESULTS_FOLDER/k6/k6.log" &
    k6_pid=$!
fi

# artillery
if [ "$ARTILLERY_ENABLED" = "true" ]; then
    mkdir -p "$TEST_CASE_RESULTS_FOLDER/artillery"
    ${ARTILLERY} run $TEST_CASE_FOLDER/artillery-config.yaml -o $TEST_CASE_RESULTS_FOLDER/artillery/artillery-report.json &> "$TEST_CASE_RESULTS_FOLDER/artillery/artillery.log" &
    artillery_pid=$!
fi

# suspend the server
if [ ! "$SERVER_PAUSE_DURATION" -eq "0" ]; then
    sleep $WARMUP_BEFORE_PAUSE

    echo "----- Suspending the server simulating a severe stall server-side"
    kill -STOP $quarkus_pid
    sleep $SERVER_PAUSE_DURATION
    echo "----- Resuming the server"
    kill -CONT $quarkus_pid
fi


echo "----- Waiting for the workload to complete"
if [ "$HF_ENABLED" = "true" ]; then
    wait $wrk_pid
fi
if [ "$K6_ENABLED" = "true" ]; then
    wait $k6_pid
fi
if [ "$ARTILLERY_ENABLED" = "true" ]; then
    wait $artillery_pid
fi
if [ "$JMETER_ENABLED" = "true" ]; then
    wait $jmeter_pid
fi

echo "----- Workload completed: killing server"

kill -SIGTERM $quarkus_pid