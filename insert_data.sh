#! /bin/bash

if [[ $1 == "test" ]]
then
  PSQL="psql --username=postgres --dbname=worldcuptest -t --no-align -c"
else
  PSQL="psql --username=freecodecamp --dbname=worldcup -t --no-align -c"
fi

# Do not change code above this line. Use the PSQL variable above to query your database.

# Start with empty tables so the script can be run more than once
$PSQL "TRUNCATE TABLE games, teams RESTART IDENTITY;" > /dev/null

while IFS="," read YEAR ROUND WINNER OPPONENT WINNER_GOALS OPPONENT_GOALS
do
  # Skip the header line
  if [[ $YEAR == "year" ]]
  then
    continue
  fi

  # Remove any Windows line ending from the last column
  OPPONENT_GOALS=${OPPONENT_GOALS%$'\r'}

  # Add both teams (skips any team already in the table)
  $PSQL "INSERT INTO teams(name) VALUES('$WINNER'), ('$OPPONENT') ON CONFLICT (name) DO NOTHING;" > /dev/null

  # Add the game, looking up each team's id
  $PSQL "INSERT INTO games(year, round, winner_id, opponent_id, winner_goals, opponent_goals)
    VALUES($YEAR, '$ROUND',
      (SELECT team_id FROM teams WHERE name = '$WINNER'),
      (SELECT team_id FROM teams WHERE name = '$OPPONENT'),
      $WINNER_GOALS, $OPPONENT_GOALS);" > /dev/null
done < games.csv
