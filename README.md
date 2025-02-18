# Load Generators Comparison

This repository aims to automate the execution of multiple load generators against the same server.

## Prerequisites

The whole automation is implemented using [qDup](https://github.com/Hyperfoil/qDup), a tool that allows shell commands to be queued up across multiple servers to coordinate performance tests.

Its execution is performed using [jbang](https://www.jbang.dev/documentation/guide/latest/), therefore the main prerequisite is this one.

Then, in according to which load generator you'd like to run, you should take care of installing the appropriate tool and make it available.


> [!NOTE]
> I am planning to automate the installation of those tools as well, currently only Hyperfoil and JBang installation as automated (if not already existing)

## Usage

If you want to run the complete automated test, simply run:

```bash
./run.sh [sut] [driver] [additional args]
```

Available SUT (Server Under Test) implementations:
- [sut](./sut/sut.yaml) - simple server taken from https://github.com/franz1981/quarkus-profiling-workshop 

Available load generators (driver):
- [hyperfoil](./drivers/hyperfoil.yaml)
- [hf wrk2](./drivers/hf-wrk2.yaml) (Hyperfoil wrk2 wrapper)
- [jmeter](./drivers/jmeter.yaml)
- [k6](./drivers/k6.yaml)
- [wrk2](./drivers/wrk2.yaml)
- [artillery](./drivers/artillery.yaml)

> [!NOTE]
> Consider running `./run.sh help` for some examples and usages.


## Load Generators

At the moment of writing these are the load generators I've been using:

### Hyperfoil

A microservice-oriented distributed benchmark framework.

Checkout https://hyperfoil.io/ for more details and how to install/download it.

### JMeter

The Apache JMeter™ application is a pure Java application designed to load test functional behavior and measure performance.

Checkout https://jmeter.apache.org/ for more details and how to install/download it.

### K6

An extensible load testing tool.

Checkout https://k6.io/open-source/ for more details and how to install/download it.

### WRK2

A HTTP benchmarking tool based mostly on wrk. wrk2 is wrk modified to produce a constant throughput load, and accurate latency details to the high 9s.

Checkout https://github.com/giltene/wrk2 for more details and how to install/download it.

### Artillery

Artillery is an open source load testing platform.

Checkout https://www.artillery.io/ for more details and how to install/download it.