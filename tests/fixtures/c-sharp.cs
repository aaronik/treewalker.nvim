using System;
using System.Collections.Generic;

namespace TestFixtureExample
{
    // A simple class representing a car
    public class Car
    {
        public string Make { get; set; }
        public string Model { get; set; }
        public int Year { get; set; }

        public Car(string make, string model, int year)
        {
            Make = make;
            Model = model;
            Year = year;
        }

        public void Start()
        {
            Console.WriteLine($"{Make} {Model} is starting.");
        }
    }

    // A class to manage a collection of cars
    public class CarCollection
    {
        private List<Car> cars;

        public CarCollection()
        {
            cars = new List<Car>();
        }

        public void AddCar(Car car)
        {
            cars.Add(car);
        }

        public void ShowCars()
        {
            foreach (var car in cars)
            {
                Console.WriteLine($"{car.Year} {car.Make} {car.Model}");
            }
        }
    }

    public class Calculator
    {
        public static int Add(int a, int b) => a + b;

        public static int Subtract(int a, int b) => a - b;

        public static int Multiply(int a, int b) => a * b;

        public static double Divide(int a, int b)
        {
            if (b == 0) throw new DivideByZeroException("Divider cannot be zero.");
            return (double)a / b;
        }
    }

    public class Program
    {
        public static void Main(string[] args)
        {
            Car car1 = new Car("Toyota", "Camry", 2020);
            Car car2 = new Car("Honda", "Civic", 2021);
            CarCollection carCollection = new CarCollection();

            carCollection.AddCar(car1);
            carCollection.AddCar(car2);
            carCollection.ShowCars();

            Console.WriteLine($"Addition: {Calculator.Add(5, 10)}");
            Console.WriteLine($"Subtraction: {Calculator.Subtract(10, 5)}");
            Console.WriteLine($"Multiplication: {Calculator.Multiply(4, 5)}");
            try
            {
                Console.WriteLine($"Division: {Calculator.Divide(10, 0)}");
            }
            catch (DivideByZeroException ex)
            {
                Console.WriteLine(ex.Message);
            }

            Function1();
            Function2();
            Function3();
            GenericMethodExample();
            ExceptionHandlingExample();
        }

        public static void Function1()
        {
            Console.WriteLine("Function1 executed.");
        }

        public static void Function2()
        {
            Console.WriteLine("Function2 executed.");
        }

        public static void Function3()
        {
            Console.WriteLine("Function3 executed.");
        }

        public static void GenericMethodExample()
        {
            var intList = new List<int> { 1, 2, 3 };
            PrintList(intList);

            var stringList = new List<string> { "A", "B", "C" };
            PrintList(stringList);
        }

        public static void PrintList<T>(List<T> list)
        {
            foreach (var item in list)
            {
                Console.WriteLine(item);
            }
        }

        public static void ExceptionHandlingExample()
        {
            try
            {
                int result = DivideNumbers(5, 0);
                Console.WriteLine(result);
            }
            catch (Exception e)
            {
                Console.WriteLine($"Exception caught: {e.Message}");
            }
        }

        public static int DivideNumbers(int numerator, int denominator)
        {
            if (denominator == 0) throw new DivideByZeroException("Denominator cannot be zero.");
            return numerator / denominator;
        }
    }
}
