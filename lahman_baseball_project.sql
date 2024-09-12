-- 1. What range of years for baseball games played does the provided database cover?

SELECT MIN(yearid), MAX(yearid)
FROM teams;
-- the database covers from year 1871 to 2016.

-- 2. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. 
-- Do the same for home runs per game. Do you see any trends?

SELECT CASE WHEN RIGHT(yearid::text, 2)::integer BETWEEN 10 AND 19 THEN '2010s' --case when 
	   		WHEN RIGHT(yearid::text, 2)::integer BETWEEN 20 AND 29 THEN '1920s'
			WHEN RIGHT(yearid::text, 2)::integer BETWEEN 30 AND 39 THEN '1930s'
			WHEN RIGHT(yearid::text, 2)::integer BETWEEN 40 AND 49 THEN '1940s'
			WHEN RIGHT(yearid::text, 2)::integer BETWEEN 50 AND 59 THEN '1950s'
			WHEN RIGHT(yearid::text, 2)::integer BETWEEN 60 AND 69 THEN '1960s'
			WHEN RIGHT(yearid::text, 2)::integer BETWEEN 70 AND 79 THEN '1970s'
			WHEN RIGHT(yearid::text, 2)::integer BETWEEN 80 AND 89 THEN '1980s'
			WHEN RIGHT(yearid::text, 2)::integer BETWEEN 90 AND 99 THEN '1990s'
			WHEN RIGHT(yearid::text, 2)::integer BETWEEN 00 AND 09 THEN '2000s'
			ELSE 'error' END AS decade,
	   ROUND(AVG(soa * 1.0/g), 2) AS strikeouts_per_game, -- soa is strikeouts (pitched, which doesn't matter), so we get the average strikeouts per game, rounded to 2 decimal points. The * 1.0 is just to get out of integers-only.
	   ROUND(AVG(HR * 1.0/g), 2) AS homeruns_per_game -- homeruns per game, same format as above
FROM teams
WHERE yearid > 1919
GROUP BY decade
ORDER BY decade;

-- Its not a perfect correlation, but both the strikeouts per game and homeruns per game have risen steadily since 1920.

-- 3. Find the player who had the most success stealing bases in 2016, where __success__ is measured as the percentage of stolen base attempts which are successful.
-- (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted _at least_ 20 stolen bases.

SELECT namefirst,
	   namelast,
	   sb,
	   cs,
	   sb+cs AS sba,
	   ROUND((sb * 1.0/(sb+cs)) * 100, 2) AS sb_success
FROM batting
INNER JOIN people
	USING(playerid)
WHERE yearid = 2016
	  AND sb+cs >= 20
ORDER BY sb_success DESC
LIMIT 1;

-- The answer is Chris Owings, who successfully stole bases 91.3% of the time.

-- 4a. From 1970 – 2016, what is the largest number of wins for a team that did not win the world series?

SELECT *
FROM teams
WHERE wswin = 'N'
	  AND yearid >= 1970
ORDER BY w DESC
LIMIT 1;

-- The Seattle Mariners, one of the baseball's more cursed franchises, won 116 games in 2001 but failed to the world series.

-- 4b. What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case.

SELECT *
FROM teams
WHERE wswin = 'Y'
	  AND yearid >= 1970
ORDER BY w
LIMIT 1;

-- The LA Dodgers won in 1981 with only 63 wins.
-- As to the why, all the teams that year played about 105-110 games as opposed to the 162 played in other years.
-- A strike in 1981 caused over a third of the games to be cancelled.

-- 4c. Then redo your query, excluding the problem year. How often from 1970 – 2016 was it the case that a team with the most wins also won the world series?
-- What percentage of the time?

WITH league_win_rank AS (SELECT name, --window function to cut out a lot of clutter and give each team a rank compared to the whole league, not just their division
	  			w,
				wswin, 
				RANK() OVER (PARTITION BY yearid ORDER BY w DESC) AS total_league_win_rank
			FROM teams
			WHERE yearid <> 1981 AND yearid >= 1970
			ORDER BY total_league_win_rank) 
SELECT
	COUNT(*) AS wswins_for_team_w_most_wins, -- note: one year didn't have a world series due to strike but count ignores nulls
	ROUND((COUNT(*)*1.0/46) * 100, 2) AS wswins_for_team_w_most_wins_percentage -- I counted the amount of years not in sql because its not like it could be different.
FROM league_win_rank
WHERE wswin = 'Y' AND total_league_win_rank = 1;

-- The team with the most amount of wins won the world series 12/46 seasons (excluding 1981), or 26.09% of seasons checked.

-- 5. It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective.
-- Investigate this claim and present evidence to either support or dispute this claim.

WITH distinct_appearance_pitchers AS (SELECT DISTINCT playerid
				      FROM appearances
				      WHERE g_p >= 10) 

SELECT
	DISTINCT throws,
	playerid,
	COUNT(*) OVER (PARTITION BY throws) AS pitchers_by_handedness,
	ROUND((COUNT(*) OVER (PARTITION BY throws)*1.0 / COUNT(*) OVER () * 100), 2) AS percentage_of_total_pitchers
FROM distinct_appearance_pitchers
	INNER JOIN people
		USING (playerid)
WHERE throws IS NOT NULL AND throws <> 'S';
	
-- 72.62% of pitchers are right-handed, 27.38% are left. There are 6195 players in the dataset that have pitched at least five times.
-- I chose 10 times since there are instances where a non-pitcher will pitch (such as in the 16th inning of particularly long games).
-- That threshold could cut off some pitchers who played very little, but only a few hundred players were removed in total and the percentage changed less than a percent.
-- Are left-handed pitchers more likely to win the Cy Young Award?

SELECT
	DISTINCT people.throws,
	COUNT(*) OVER (PARTITION BY throws) AS cy_young_winners,
	ROUND((COUNT(*) OVER (PARTITION BY throws)*1.0 / COUNT(*) OVER ()) * 100, 2) AS percentage_of_total_winners
FROM awardsplayers
	INNER JOIN people
		USING (playerid)
WHERE awardid = 'Cy Young Award';

-- There are 37 left-handed Cy Young winners compared to 75 right-handed ones. This comes out to about 1/3 left and 2/3s right.
-- Not a large difference, but 33% of lefties have won compared to 27% of pitchers being left-handed is a slight preference to left-handers.

-- Are they more likely to make it into the hall of fame?

WITH distinct_appearance_pitchers AS (SELECT DISTINCT playerid
				      FROM appearances
				      WHERE g_p >= 10) --filtering out all players that aren't pitchers, same criteria as above
							-- it should be noted that at least babe ruth started as a pitcher, though he became famous as a hitter. 
							-- He pitched for several seasons, meaning there wasn't a good way to filter him, 
							-- and anyone who was in a similar boat, out from the data.
									   
SELECT
	people.throws,
	people.namefirst || ' ' || people.namelast AS full_name,
	COUNT(*) OVER (PARTITION BY throws) AS hof_members,
	ROUND((COUNT(*) OVER (PARTITION BY throws)*1.0 / COUNT(*) OVER ()) * 100, 2) AS percentage_of_hof_pitchers
FROM halloffame
	INNER JOIN distinct_appearance_pitchers
		USING (playerid)
	INNER JOIN people
		USING (playerid)
WHERE inducted = 'Y' AND category = 'Player'; --I did this just in case some left-handed pitcher played a couple mediocre season but went on to be a HoF manager.
							 --There 5 HoF members removed, even though the percentages didn't change much
							 
-- In the Hall of Fame, there are 74 pitchers. 18 of these are lefties, and 56 right-handed.
-- That comes out to 24.32% lefties, and 75.68% right.
-- That's actually lower than the total percentage of left-handed pitchers in the league, though going from a sample composed of 1000s to one composed of dozens could account for that weirdness.
-- Either way, it doesn't seem like a disproportionate level of lefties reach the HoF.

-- However, Cy Young winners do appear to be skewed towards the lefties, so I'm going to look deeper into that.

-- First I'm going to look at players who won the Cy Young award multiple times.
-- Its possible that even though lefties aren't more likely to be successful, a few really good lefties are skewing the award average.

WITH cy_young_wins_total AS (SELECT playerid,
	   		     COUNT(*) AS number_of_cy_young_wins
			     FROM awardsplayers
			     WHERE awardid = 'Cy Young Award'
			     GROUP BY playerid)						 
SELECT
	people.throws,
	COUNT(playerid) AS total_cy_young_winners,
	SUM(number_of_cy_young_wins) AS total_cy_young_wins
FROM people
	INNER JOIN cy_young_wins_total
		USING (playerid)
WHERE number_of_cy_young_wins > 1
GROUP BY throws
ORDER BY total_cy_young_winners DESC;

SELECT 19*1.0/(34+19);

-- The results indicate that my previous hypothesis is correct. While 25~% of pitchers are lefties, and 1/3 of Cy Young winners have been left-handed,
-- if we look at the player who have won Cy Youngs multiple times, half of them are lefties (6 compared to 12), a much higher percentage compared to our larger sample size.
-- Among those who have won multiple awards, 35% of those awards have gone to lefties, which is similar to the total percentage of cy young winners as lefties.
-- To double-check, I'll look at the pitchers who have only won the Cy Young once to see if it supports this idea.

WITH cy_young_wins_total AS (SELECT playerid,
	   						 COUNT(*) AS number_of_cy_young_wins
					   		 FROM awardsplayers
							 WHERE awardid = 'Cy Young Award'
							 GROUP BY playerid)						 
SELECT DISTINCT people.throws,
	   COUNT(playerid) OVER (PARTITION BY throws) AS cy_young_winners,
	   ROUND((COUNT(playerid) OVER (PARTITION BY throws)*1.0 / COUNT(*) OVER ()) * 100, 2) AS percentage_of_cy_young_pitchers
FROM people
	INNER JOIN cy_young_wins_total
		USING (playerid)
WHERE number_of_cy_young_wins = 1;

-- Here our hypothesis is also supported.
-- Out of the 59 pitchers who have only won the Cy Young once, the ratio of lefties to righties is 30.5%:69.50%
-- This is slightly skewed towards lefties compared to the larger data, but that could explained by random chance due to sample size.
-- For the record, only one less left-handed pitcher winning compared to a right-hander puts the percentage at 28.81%
-- which is nearly identical to the amount of left-handed pitchers in the league at large.
