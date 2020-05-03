func EditDistance(source, target string) int {
	if len(source) == 0 {
		return len(target)
	}

	if len(target) == 0 {
		return len(source)
	}

	sourceChars := []rune(source)
	targetChars := []rune(target)

	cache := make([]int, len(target)+1)
	for i := 0; i < len(target)+1; i++ {
		cache[i] = i
	}

	for i, sourceChar := range sourceChars {
		nextDist := i + 1
		for j, targetChar := range targetChars {
			currentDist := nextDist

			distIfSubstitute := cache[j]
			if sourceChar != targetChar {
				distIfSubstitute++
			}

			distIfInsert := currentDist + 1
			distIfDelete := cache[j+1] + 1

			nextDist = min(distIfDelete, min(distIfInsert, distIfSubstitute))

			cache[j] = currentDist
		}

		cache[len(target)] = nextDist
	}

	return cache[len(target)]
}
