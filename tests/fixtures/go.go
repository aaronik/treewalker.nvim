package main

import "fmt"

func main() {
	var x = 1
	var y = 2
	var z = 3

	if x > 0 {
		fmt.Println("positive")
	}

	if y > 0 {
		fmt.Println("also positive")
	}
}

func helper() {
	var a = 10
	var b = 20
}

func switchCondition() {
	i := 2
	switch i {
	case 1:
		fmt.Println("one")
	case 2:
		fmt.Println("two")
	case 3:
		fmt.Println("three")
	}
	fmt.Println("done")
}
