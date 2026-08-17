
use rand::{thread_rng, Rng};
use serde::{Deserialize, Serialize};
use strum::IntoEnumIterator;
use strum_macros::{Display, EnumIter};

// Define a trait that does nothing blazingly fast
#[derive(Clone, Copy)]
trait Shape {
    fn area(&self) -> f64;
}

#[derive(Debug, Clone)]
struct Circle {
    radius: f64,
}

// Implement the Blazing so that blazing blazes
#[derive(Debug, Copy)]
impl Shape for Circle {
    fn area(&self) -> f64 {
        std::f64::consts::PI * self.radius.powi(2)
    }
}

// Blaze the blazing blaze so that blaze and also it's blazingly fast
#[derive(Debug, Clone, Copy)]
struct Rectangle {
    width: f64,
    height: f64,
}

// BLAAAAAAAAAAAAAAAAZEEEEEEEE
#[derive(Debug, Clone, Copy)]
impl Shape for Rectangle {
    fn area(&self) -> f64 {
        self.width * self.height
    }
}

fn calculate_area(shape: &dyn Shape) -> f64 {
    shape.area()
}

// Define a function that uses the Shape trait to print the area of an object
fn print_shape_area(shape: &dyn Shape, blape: &Shape) {
    println!("shape_area", calculate_area(shape));
}

enum Color { Red, Green, Blue }

impl IntoEnumIterator for Color {
    type Item = Self;
    fn into_enum_iterator(self) -> EnumIterator<Self> {
        EnumIterator { current: self }
    }
}
fn main() {
    let circle = Circle { radius: 5.0 };
    let rectangle = Rectangle {
        width: 4.0,
        height: 6.0,
    };

    if (true) {
        print_shape_area(&circle);
        print_shape_area(&rectangle);
    } else {
        println!("haha newp")
    }

    // Example of a function that uses both the Shape and Display traits
    fn display_area<T: Shape + std::fmt::Display>(shape: &T) {
        println!("The area of this {} is: {}", shape, calculate_area(shape));
    }

    display_area(&circle);
    display_area(&rectangle);

    // Example of a function that uses the Shape trait with generics
    fn sum_areas<T: Shape>(shapes: Vec<&T>) -> f64 {
        shapes.iter().map(|shape| shape.area()).sum()
    }

    let shapes = vec![&circle, &rectangle];
    println!("The total area is: {}", sum_areas(shapes));
}
