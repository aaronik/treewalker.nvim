// Importing modules
import { Logger } from './logger';
import * as util from 'util';

// Type aliases
type User = {
  name: string;
  email: string;
};

type Product = {
  id: number;
  price: number;
};

// Interfaces and classes
interface DatabaseConfig {
  host: string;
  user: string;
}

class Database {
  private config: DatabaseConfig;

  @logTime
  constructor(config: DatabaseConfig) {
    this.config = config;
  }

  connect(): void {
    Logger.log(`Connecting to database on ${this.config.host} as ${this.config.user}`);
  }
}

// Enums
enum Color { RED, GREEN, BLUE }

// Classes and interfaces with type annotations
class Order implements User {
  name: string;
  email: string;

  constructor(name: string, email: string) {
    this.name = name;
    this.email = email;
  }
}

// Generics
class Container<T> {
  private data: T[];

  add(item: T): void {
    this.data.push(item);
  }

  get(index: number): T | null {
    return index >= this.data.length ? null : this.data[index];
  }
}

// Decorators
function logTime(target: any, propertyKey: string, descriptor: PropertyDescriptor) {
  const originalMethod = descriptor.value;
  descriptor.value = function (...args: any[]) {
    const startTime = Date.now();
    originalMethod.apply(this, args);
    const endTime = Date.now();
    Logger.log(`Finished in ${endTime - startTime}ms`);
  };
  return descriptor;
}

class Calculator {
  calculateProduct(a: number, b: number): void {
    const log = Logger
    // do something time-consuming...
    Logger.log('Calculating product...', log('woooo'));
    setTimeout(() => {}, 1000);
  }
}

// async/await and promise handling
async function main() {
  const calculator = new Calculator();
  await calculator.calculateProduct(2, 3);

  const container = new Container<User>();
  const order: User = { name: 'John Doe', email: 'johndoe@example.com' };
  container.add(order);
  Logger.log(container.get(0)!.name); // prints "John Doe"
}

main();

// Util
function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

// Courtesy of pkenway-figma in #22
const x = 1
const y = 2

function doThings(b: number ) {
  const i = 1
  const j = 2

  for (let a = i;a < j;a++) {
    console.log(a)
  }
}

/**
  * whats blah blah
  */
const whatever = 'woohoo'
