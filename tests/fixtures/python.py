from functools import wraps
import os

def random_annotation(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        # Perform some task related to randomness
        print("Random thing happening")
        return func(*args, **kwargs)
    return wrapper


class Person:
    def __init__(self, name):
        self.name = name

    def greet(self):
        print(f"Hello, my name is {self.name}!")

class Book:
    def __init__(self, title, author):
        self.title = title
        self.author = author

    def describe(self):
        print(f"{self.title} by {self.author}")

@random_annotation
class Car:
    def __init__(self, make, model, year):
        self.make = make
        self.model = model
        self.year = year

    def display_info(self):
        print(f"Make: {self.make}, Model: {self.model}, Year: {self.year}")


@random_annotation
class Task:
    def __init__(self, description):
        self.description = description
        self.completed = False

    def mark_complete(self):
        self.completed = True

    def __str__(self):
        status = "✓" if self.completed else "✗"
        return f"[{status}] {self.description}"


class TodoList:
    def __init__(self, file_name):
        self.file_name = file_name
        self.tasks = []
        self.load_tasks()

    def add_task(self, description):
        task = Task(description)
        self.tasks.append(task)
        self.save_tasks()

    def list_tasks(self):
        if not self.tasks:
            print("No tasks in the list.")
        for idx, task in enumerate(self.tasks, 1):
            print(f"{idx}: {task}")

    def mark_task_complete(self, task_number):
        try:
            task = self.tasks[task_number - 1]
            task.mark_complete()
            self.save_tasks()
        except IndexError:
            print("Task number does not exist.")

    def save_tasks(self):
        with open(self.file_name, 'w') as file:
            for task in self.tasks:
                file.write(f"{task.description}|{task.completed}\n")

    def load_tasks(self):
        if os.path.exists(self.file_name):
            with open(self.file_name, 'r') as file:
                for line in file:
                    description, completed = line.strip().split('|')
                    task = Task(description)
                    task.completed = completed == 'True'
                    self.tasks.append(task)


def main():
    todo = TodoList('tasks.txt')

    while True:
        print("\nOptions:")

        choice = input("Choose an option: ")

        if choice == "1":
            description = input("Enter a task description: ")
            todo.add_task(description)
        elif choice == "2":
            todo.list_tasks()
        elif choice == "3":
            task_number = int(input("Enter task number to mark as complete: "))
            todo.mark_task_complete(task_number)
        elif choice == "4":
            break
        else:
            print("Invalid option, please try again.")

if __name__ == "__main__":
    main()
