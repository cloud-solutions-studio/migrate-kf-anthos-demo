projects/216052643607/services/proj-216052643607-spring-books-productpage
{
      "serviceLevelIndicator": {
        "basicSli": {
          "availability": {}
        }
      },
      "goal": 0.9,
      "rollingPeriod": "86400s",
      "displayName": "90% - Availability - Rolling day"
    }

projects/216052643607/services/proj-216052643607-spring-books-ratings
{
  "displayName": "80% - Latency - Rolling day",
  "goal": 0.8,
  "rollingPeriod": "86400s",
  "serviceLevelIndicator": {
    "basicSli": {
      "latency": {
        "threshold": "0.0025s"
      }
    }
  }
}
projects/216052643607/services/proj-216052643607-spring-books-reviews
{
  "displayName": "75% - Availability - Calendar day",
  "goal": 0.95,
  "serviceLevelIndicator": {
    "basicSli": {
      "availability": {}
    }
  },
  "calendarPeriod": "DAY"
}
projects/216052643607/services/proj-216052643607-spring-books-details
{
  "displayName": "80% - Latency - Rolling day",
  "goal": 0.8,
  "serviceLevelIndicator": {
    "basicSli": {
      "latency": {
        "threshold": "0.0615s"
      }
    }
  },
  "rollingPeriod": "86400s"
}
