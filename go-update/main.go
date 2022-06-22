package main

import (
	"bufio"
	"fmt"
	"log"
	"os"

	"github.com/blang/semver"
	"github.com/rhysd/go-github-selfupdate/selfupdate"
)

const repo = "accuknox/accuknox-cli"

const version = "1.2.3"

func checkLatest() {
	latest, found, err := selfupdate.DetectLatest(repo)
	if err != nil {
		log.Println("Error occurred while detecting version:", err)
		return
	}
	log.Printf("found=%+v latest=%+v", found, latest)

	v := semver.MustParse(version)
	if !found || latest.Version.LTE(v) {
		log.Println("Current version is the latest")
		return
	}

	fmt.Print("Do you want to update to", latest.Version, "? (y/n): ")
	input, err := bufio.NewReader(os.Stdin).ReadString('\n')
	if err != nil || (input != "y\n" && input != "n\n") {
		log.Println("Invalid input")
		return
	}
}

func main() {
	v := semver.MustParse(version)
	checkLatest()
	latest, err := selfupdate.UpdateSelf(v, repo)
	if err != nil {
		log.Println("Binary update failed:", err)
		return
	}
	if latest.Version.Equals(v) {
		// latest version is the same as current version. It means current binary is up to date.
		log.Println("Current binary is the latest version", version)
	} else {
		log.Println("Successfully updated to version", latest.Version)
		log.Println("Release note:\n", latest.ReleaseNotes)
	}
}
