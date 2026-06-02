const CARDS = { # Attack, Health, Energy, Type, Ability, Ability Script
	"Virus" : [1, 2, 1, "Attacker", null, null],
	"Phishing" : [null, null, 2, "Support", "Steal 1 random card from your opponent's deck. They won't know what's gone until it's too late.", "res://Scripts/Abilities/Phishing.gd"],
	"Worm" : [2, 1, 4, "Attacker", null, null],
	"Trojan" : [1, 3, 5, "Attacker", null, null],
	"Backdoor" : [null, null, 3, "Support", "Breach opponent's defenses, attacking their card or HP directly.", "res://Scripts/Abilities/Backdoor.gd"]
}
