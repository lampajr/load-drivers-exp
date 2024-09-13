import http from 'k6/http';

export const options = {
  discardResponseBodies: true,
  scenarios: {
    "simple-request": {
      executor: 'constant-arrival-rate',

      // How long the test lasts
      duration: '40s',

      // How many iterations per timeUnit
      rate: 100,

      // Start `rate` iterations per second
      timeUnit: '1s',

      // Pre-allocate 2 VUs before starting the test
      preAllocatedVUs: 30,

      // Spin up a maximum of 30 VUs to sustain the defined
      // constant arrival rate.
      maxVUs: 30,
    },
  },
};


export default function () {
  const response = http.get('http://localhost:8080/time/cached');
}
