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
	// case values can be any value, constants are not mandatory

	i := 2
	switch i { //
	case 1:
		fmt.Println("one")
		// fallthrough // this is a special keyword that lets you fallthrough to the next case
		//                because in go, switch exits after first returned value / last executed statement
	case 2:
		fmt.Println("two")
	case 3:
		fmt.Println("three")
	}
	fmt.Println("done")
}

func sum(nums ...int) {
	total := 0
	for _, num := range nums {
		total += num
	}
	fmt.Println(total)
}
