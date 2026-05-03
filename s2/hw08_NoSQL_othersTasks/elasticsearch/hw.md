# Домашнее задание

1. Поднять Elastic
2. Создать индекс
3. Заполнить данными
4. Написать 4 запроса (поиск по названию, фильтры, `match`, `range`, `term`, `bool`)

```json
{
  "info": {
    "name": "Elastic Search - ДЗ Запросы",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": [
    {
      "name": "1. Match query - поиск по названию",
      "request": {
        "method": "GET",
        "header": [],
        "body": {
          "mode": "raw",
          "raw": "{\n    \"query\": {\n        \"match\": {\n            \"title\": {\n                \"query\": \"беспроводные наушники\",\n                \"operator\": \"and\"\n            }\n        }\n    },\n    \"highlight\": {\n        \"fields\": {\n            \"title\": {}\n        }\n    }\n}"
        },
        "url": {
          "raw": "localhost:9200/first_index/_search",
          "host": ["localhost"],
          "port": "9200",
          "path": ["first_index", "_search"]
        }
      }
    },
    {
      "name": "2. Range query - фильтр по цене",
      "request": {
        "method": "GET",
        "header": [],
        "body": {
          "mode": "raw",
          "raw": "{\n    \"query\": {\n        \"range\": {\n            \"price\": {\n                \"gte\": 100,\n                \"lte\": 300\n            }\n        }\n    },\n    \"sort\": [\n        {\"price\": {\"order\": \"asc\"}}\n    ]\n}"
        },
        "url": {
          "raw": "localhost:9200/first_index/_search",
          "host": ["localhost"],
          "port": "9200",
          "path": ["first_index", "_search"]
        }
      }
    },
    {
      "name": "3. Term query - точное совпадение",
      "request": {
        "method": "GET",
        "header": [],
        "body": {
          "mode": "raw",
          "raw": "{\n    \"query\": {\n        \"term\": {\n            \"available\": true\n        }\n    },\n    \"sort\": [\n        {\"price\": {\"order\": \"desc\"}}\n    ],\n    \"size\": 10\n}"
        },
        "url": {
          "raw": "localhost:9200/first_index/_search",
          "host": ["localhost"],
          "port": "9200",
          "path": ["first_index", "_search"]
        }
      }
    },
    {
      "name": "4. Bool query - комбинированный поиск",
      "request": {
        "method": "GET",
        "header": [],
        "body": {
          "mode": "raw",
          "raw": "{\n    \"query\": {\n        \"bool\": {\n            \"must\": [\n                {\n                    \"match\": {\n                        \"title\": \"беспроводной\"\n                    }\n                }\n            ],\n            \"filter\": [\n                {\n                    \"range\": {\n                        \"price\": {\n                            \"gte\": 50,\n                            \"lte\": 200\n                        }\n                    }\n                },\n                {\n                    \"term\": {\n                        \"available\": true\n                    }\n                }\n            ],\n            \"should\": [\n                {\n                    \"match\": {\n                        \"title\": \"мышь\"\n                    }\n                }\n            ],\n            \"minimum_should_match\": 1\n        }\n    }\n}"
        },
        "url": {
          "raw": "localhost:9200/first_index/_search",
          "host": ["localhost"],
          "port": "9200",
          "path": ["first_index", "_search"]
        }
      }
    }
  ]
}
```