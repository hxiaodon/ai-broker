package main

import "mobile/mock-server/strategies"

var currentStrategy strategies.Strategy

func getStrategy(name string) strategies.Strategy {
	switch name {
	case "normal":
		return &strategies.NormalStrategy{}
	case "delayed":
		return &strategies.DelayedStrategy{}
	case "unstable":
		return &strategies.UnstableStrategy{}
	case "error":
		return &strategies.ErrorStrategy{}
	case "guest":
		return &strategies.GuestStrategy{}
	default:
		return &strategies.NormalStrategy{}
	}
}
