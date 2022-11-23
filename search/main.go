package main

import (
	"fmt"
	"strings"

	"golang.org/x/exp/slices"
)

func main() {
	policyType := "KubearmorSecurityPolicy,CiliumNetworkPolicy"
	if strings.Contains(policyType, "CiliumNetworkPolicy") {
		fmt.Println("cilium")
	}
	if strings.Contains(policyType, "NetworkPolicy") {
		fmt.Println("generic")
	}
	pt := strings.Split(policyType, ",")
	if slices.IndexFunc(pt, func(c string) bool { return c == "CiliumNetworkPolicy" }) > -1 {
		fmt.Println("cilium")
	}
	if slices.IndexFunc(pt, func(c string) bool { return c == "NetworkPolicy" }) > -1 {
		fmt.Println("generic")
	}
}
