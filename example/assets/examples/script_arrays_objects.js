// Script Mode - Arrays and Objects
// Array and object operations

// Array operations
const numbers = [1, 2, 3, 4, 5];
numbers
  .map(x => x * 2)
  .filter(x => x > 5)
  .reduce((sum, x) => sum + x, 0)

// Object operations
const user = {
  name: "Alice",
  age: 30,
  skills: ["JavaScript", "Flutter", "Dart"]
};
({
  ...user,
  age: user.age + 1,
  skillCount: user.skills.length
})
