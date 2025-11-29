package com.example.treewalker;

import java.util.List;
import java.util.ArrayList;
import java.util.Map;
import java.util.HashMap;
import java.util.stream.Collectors;

/**
 * Main demo class for testing treewalker navigation
 * across various Java constructs
 */
public class JavaDemo {
  private String name;
  private int count;
  private static final int MAX_SIZE = 100;

  // Default constructor
  public JavaDemo() {
    this.name = "default";
    this.count = 0;
  }

  // Parameterized constructor
  public JavaDemo(String name, int count) {
    this.name = name;
    this.count = count;
  }

  /**
   * Gets the name value
   * @return the name
   */
  public String getName() {
    return name;
  }

  // Setter with validation
  public void setName(String name) {
    if (name == null) {
      throw new IllegalArgumentException("Name cannot be null");
    }
    this.name = name;
  }

  public int getCount() {
    return count;
  }

  public void setCount(int count) {
    this.count = count;
  }

  // Static method with control flow
  public static List<String> filterNames(List<String> names) {
    List<String> result = new ArrayList<>();
    for (String name : names) {
      if (name != null && name.length() > 0) {
        result.add(name);
      }
    }
    return result;
  }

  // Method with try-catch
  public void processData(String data) {
    try {
      int value = Integer.parseInt(data);
      this.count = value;
    } catch (NumberFormatException e) {
      System.err.println("Invalid number format: " + data);
      this.count = 0;
    } finally {
      System.out.println("Processing complete");
    }
  }

  // Method with lambda expression
  public List<Integer> doubleNumbers(List<Integer> numbers) {
    return numbers.stream()
      .map(n -> n * 2)
      .collect(Collectors.toList());
  }

  // Method with switch statement
  public String getStatusMessage(int code) {
    switch (code) {
      case 200:
        return "OK";
      case 404:
        return "Not Found";
      case 500:
        return "Server Error";
      default:
        return "Unknown";
    }
  }

  // Method with while loop
  public int calculateSum(int n) {
    int sum = 0;
    int i = 1;
    while (i <= n) {
      sum += i;
      i++;
    }
    return sum;
  }

  /**
   * Inner class for data storage
   */
  public static class DataHolder {
    private Map<String, Object> data;

    public DataHolder() {
      this.data = new HashMap<>();
    }

    public void put(String key, Object value) {
      data.put(key, value);
    }

    public Object get(String key) {
      return data.get(key);
    }
  }

  /**
   * Status enum
   */
  public enum Status {
    ACTIVE,
    INACTIVE,
    PENDING
  }

  /**
   * Interface for callback
   */
  public interface Callback {
    void onComplete(String result);
    void onError(Exception e);
  }

  // Generic method
  public <T> List<T> createList(T item) {
    List<T> list = new ArrayList<>();
    list.add(item);
    return list;
  }

  // Annotated method
  @Override
  public String toString() {
    return "JavaDemo{name='" + name + "', count=" + count + "}";
  }

  @Override
  public boolean equals(Object obj) {
    if (this == obj) return true;
    if (obj == null || getClass() != obj.getClass()) return false;
    JavaDemo other = (JavaDemo) obj;
    return count == other.count && name.equals(other.name);
  }

  @Override
  public int hashCode() {
    int result = name.hashCode();
    result = 31 * result + count;
    return result;
  }

  // Method with multiple parameters and nested calls
  public void complexOperation(String input, int threshold, boolean flag) {
    if (flag) {
      processData(input);
      if (count > threshold) {
        setName("high");
      } else {
        setName("low");
      }
    }
  }

  // Main method for testing
  public static void main(String[] args) {
    JavaDemo demo = new JavaDemo("test", 42);
    System.out.println(demo.getName());
    System.out.println(demo.getCount());

    List<String> names = new ArrayList<>();
    names.add("Alice");
    names.add("Bob");
    names.add("Charlie");

    List<String> filtered = filterNames(names);
    for (String name : filtered) {
      System.out.println(name);
    }

    demo.processData("123");
    demo.complexOperation("data", 50, true);
  }
}
