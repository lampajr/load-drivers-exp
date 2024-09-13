#!/bin/bash

# set -x trace
CURRENT_DIR=$(dirname $0)

###################################
#### overridable configuration ####
###################################

TEST_CASE=${TEST_CASE:-"simple_request_100_rps"}

THREADS=${THREADS:-10}
QUARKUS_BACKLOG=${QUARKUS_BACKLOG:-"-1"}
QUARKUS_CONNECTIONS=${QUARKUS_CONNECTIONS:-"100"}
QUARKUS_IDLE_TIMEOUT=${QUARKUS_IDLE_TIMEOUT:-"30M"}

WARMUP_BEFORE_PAUSE=${WARMUP_BEFORE_PAUSE:-20}
SERVER_PAUSE_DURATION=${SERVER_PAUSE_DURATION:-7}
CLIENT_PAUSE_DURATION=${CLIENT_PAUSE_DURATION:-0}

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

java -Dquarkus.log.level=INFO -Dquarkus.vertx.event-loops-pool-size=${THREADS} -Dquarkus.http.idle-timeout=${QUARKUS_IDLE_TIMEOUT} -Dquarkus.http.accept-backlog=${QUARKUS_BACKLOG} -Dquarkus.http.limits.max-connections=${QUARKUS_CONNECTIONS} -XX:+UnlockDiagnosticVMOptions -XX:+DebugNonSafepoints -jar $CURRENT_DIR/../quarkus-profiling-workshop/target/quarkus-app/quarkus-run.jar &
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
    echo "----- Hyperfoil started with pid ${wrk_pid}"
fi

# jmeter
if [ "$JMETER_ENABLED" = "true" ]; then
    mkdir -p "$TEST_CASE_RESULTS_FOLDER/jmeter"
    ${JMETER} -n -t $TEST_CASE_FOLDER/jmeter-config.jmx -l $TEST_CASE_RESULTS_FOLDER/jmeter/log.jtl -j $TEST_CASE_RESULTS_FOLDER/jmeter/jmeter.log -e -o $TEST_CASE_RESULTS_FOLDER/jmeter/jmeter-report -f >/dev/null &
    jmeter_pid=$!
    echo "----- Jmeter started with pid ${jmeter_pid}"
fi

# k6
if [ "$K6_ENABLED" = "true" ]; then
    mkdir -p "$TEST_CASE_RESULTS_FOLDER/k6"
    ${K6} run --summary-trend-stats="avg,min,med,max,p(50),p(75),p(90),p(99),p(99.9),p(99.99),p(99.999),count" --out json=$TEST_CASE_RESULTS_FOLDER/k6/k6-output.json $TEST_CASE_FOLDER/k6-config.js &> "$TEST_CASE_RESULTS_FOLDER/k6/k6.log" &
    k6_pid=$!
    echo "----- K6 started with pid ${k6_pid}"
fi

# artillery
if [ "$ARTILLERY_ENABLED" = "true" ]; then
    mkdir -p "$TEST_CASE_RESULTS_FOLDER/artillery"
    ${ARTILLERY} run $TEST_CASE_FOLDER/artillery-config.yaml -o $TEST_CASE_RESULTS_FOLDER/artillery/artillery-report.json &> "$TEST_CASE_RESULTS_FOLDER/artillery/artillery.log" &
    artillery_pid=$!
    echo "----- Artillery started with pid ${artillery_pid}"
fi

# suspend the server
if [ ! "$SERVER_PAUSE_DURATION" -eq "0" ]; then
    sleep $WARMUP_BEFORE_PAUSE

    echo "----- Suspending the server for ${SERVER_PAUSE_DURATION}s"
    kill -STOP $quarkus_pid
    sleep $SERVER_PAUSE_DURATION
    echo "----- Resuming the server"
    kill -CONT $quarkus_pid
fi

# suspend the client
if [ ! "$CLIENT_PAUSE_DURATION" -eq "0" ]; then
    sleep $WARMUP_BEFORE_PAUSE

    if [ "$HF_ENABLED" = "true" ]; then
        echo "----- Suspending the hyperfoil load generator for ${CLIENT_PAUSE_DURATION}s"
        hf_pid=$(ps aux | grep 'io.hyperfoil.cli.commands.Wrk2' | grep -v grep | awk '{print $2}')
        kill -STOP $hf_pid
    fi
    if [ "$K6_ENABLED" = "true" ]; then
        echo "----- Suspending the k6 load generator for ${CLIENT_PAUSE_DURATION}s"
        kill -STOP $k6_pid
    fi
    if [ "$ARTILLERY_ENABLED" = "true" ]; then
        echo "----- Suspending the artillery load generator for ${CLIENT_PAUSE_DURATION}s"
        kill -STOP $artillery_pid
    fi
    if [ "$JMETER_ENABLED" = "true" ]; then
        echo "----- Suspending the jmeter load generator for ${CLIENT_PAUSE_DURATION}s"
        kill -STOP $jmeter_pid
    fi

    sleep $CLIENT_PAUSE_DURATION
    echo "----- Resuming the load generators"

    if [ "$HF_ENABLED" = "true" ]; then
        echo "----- Resuming the hyperfoil load generator"
        kill -CONT $hf_pid
    fi
    if [ "$K6_ENABLED" = "true" ]; then
        echo "----- Resuming the k6 load generator"
        kill -CONT $k6_pid
    fi
    if [ "$ARTILLERY_ENABLED" = "true" ]; then
        echo "----- Resuming the artillery load generator"
        kill -CONT $artillery_pid
    fi
    if [ "$JMETER_ENABLED" = "true" ]; then
        echo "----- Resuming the jmeter load generator"
        kill -CONT $jmeter_pid
    fi
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