alias MtgFriends.{Tournaments, Participants, Repo}

tournament = %Tournaments.Tournament{
  name: "TEST",
  location: "Cancun",
  date: ~D[2023-11-03],
  active: true,
  description: "test description"
}

tournament = Repo.insert!(tournament)

participant =
  Ecto.build_assoc(tournament, :participants, %Participants.Participant{
    name: "Juan",
    points: 0
  })

Repo.insert!(participant)
