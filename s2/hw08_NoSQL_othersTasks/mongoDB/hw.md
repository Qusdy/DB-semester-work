## Задание

- Поднять в docker compose mongoDB
- Создать минимум 3 коллекции, хотя бы 2 из которых связаны `ObjectId`, хотя бы 1 из документов в коллекции хранят JSON объекты либо массивы
- Наполнить каждую коллекцию необходимым количеством данных

---

### Коллекция students

```bash
db.students.insertMany([
  {
    name: "Миш снетк",
    age: 21,
    address: {
      city: "Казань",
      street: "Кремлевская, 35",
      building: 25
    }
  },
  {
    name: "Жен Пер",
    age: 19,
    address: {
      city: "Вашингтон",
      street: "Белый дом",
      building: 115
    }
  },
  {
    name: "Artur abdul",
    age: 22,
    address: {
      city: "Казань",
      street: "Баумана",
      building: 7
    }
  }
])
```

```bash
{
  acknowledged: true,
  insertedIds: {
    '0': ObjectId('69f5010e4a3a0396b944ba89'),
    '1': ObjectId('69f5010e4a3a0396b944ba8a'),
    '2': ObjectId('69f5010e4a3a0396b944ba8b')
  }
}
```

### Коллекция courses

```bash
db.courses.insertMany([
  {
    title: "MongoDB для начинающих",
    credits: 3,
    topics: ["Введение", "CRUD операции", "Индексы"]
  },
  {
    title: "Продвинутая агрегация",
    credits: 5,
    topics: ["$group", "$lookup", "$unwind", "$facet"]
  },
  {
    title: "Оптимизация запросов",
    credits: 4,
    topics: ["Планы выполнения", "Индексация", "Sharding"]
  }
])
```

```bash
{
  acknowledged: true,
  insertedIds: {
    '0': ObjectId('69f501314a3a0396b944ba8c'),
    '1': ObjectId('69f501314a3a0396b944ba8d'),
    '2': ObjectId('69f501314a3a0396b944ba8e')
  }
}
```

### Коллекция связей

```bash
var students = db.students.find().toArray()
var courses = db.courses.find().toArray()

db.enrollments.insertMany([
  {
    student_id: students[0]._id,  // Я
    course_id: courses[0]._id,    // MongoDB для начинающих
    year: 2025,
    grades: [85, 90, 88, 92]
  },
  {
    student_id: students[0]._id,  // Я
    course_id: courses[1]._id,    // Продвинутая агрегация
    year: 2025,
    grades: [78, 82, 85]
  },
  {
    student_id: students[1]._id,  // женя
    course_id: courses[0]._id,    // MongoDB для начинающих
    year: 2024,
    grades: [92, 94, 96, 98]
  },
  {
    student_id: students[1]._id,  // женя
    course_id: courses[2]._id,    // Оптимизация запросов
    year: 2025,
    grades: [88, 85, 90]
  },
  {
    student_id: students[2]._id,  // артурчик
    course_id: courses[0]._id,    // MongoDB для начинающих
    year: 2025,
    grades: [95, 97, 94, 96]
  },
  {
    student_id: students[2]._id,  // артурчик
    course_id: courses[1]._id,    // Продвинутая агрегация
    year: 2025,
    grades: [88, 90]
  },
  {
    student_id: students[2]._id,  // артурчик
    course_id: courses[2]._id,    // Оптимизация запросов
    year: 2025,
    grades: [85, 87, 89]
  },
])
```

```bash
{
  acknowledged: true,
  insertedIds: {
    '0': ObjectId('69f501544a3a0396b944ba8f'),
    '1': ObjectId('69f501544a3a0396b944ba90'),
    '2': ObjectId('69f501544a3a0396b944ba91'),
    '3': ObjectId('69f501544a3a0396b944ba92'),
    '4': ObjectId('69f501544a3a0396b944ba93'),
    '5': ObjectId('69f501544a3a0396b944ba94'),
    '6': ObjectId('69f501544a3a0396b944ba95')
  }
}
```

---

- Написать 2 `find` запроса, хотя бы 1 с projection (`{ field1: 0, field2: 1 }`)

---

## 1

```bash
db.students.find(
  {"address.city": "Казань"},
  {name: 1, _id: 0}
)
```

```bash
[ { name: 'Миш снетк' }, { name: 'Artur abdul' } ]
```

## 2

```bash
db.students.find({name: /^Ж/})
[
  {
    _id: ObjectId('69f5010e4a3a0396b944ba8a'),
    name: 'Жен Пер',
    age: 19,
    address: { city: 'Вашингтон', street: 'Белый дом', building: 115 }
  }
]
```

---

- Написать 2 `update` запроса

---

## 1

```bash
db.students.updateOne(
  { name: "Жен Пер" },
  { $set: { name: "Евгений Перврзв" } }
)
{
  acknowledged: true,
  insertedId: null,
  matchedCount: 1,
  modifiedCount: 1,
  upsertedCount: 0
}
```

## 2

```bash
db.courses.updateOne(
  { title: "MongoDB для начинающих" },
  { $push: { topics: "Индексы" } }
)
{
  acknowledged: true,
  insertedId: null,
  matchedCount: 1,
  modifiedCount: 1,
  upsertedCount: 0
}
```

---

- Написать 1 любой запрос с `aggregate`

---

```bash
db.enrollments.aggregate([
  { $group: { _id: "$student_id", coursesCount: { $sum: 1 } } }
])
[
  { _id: ObjectId('69f5010e4a3a0396b944ba8a'), coursesCount: 2 },
  { _id: ObjectId('69f5010e4a3a0396b944ba89'), coursesCount: 2 },
  { _id: ObjectId('69f5010e4a3a0396b944ba8b'), coursesCount: 3 }
]
```

---