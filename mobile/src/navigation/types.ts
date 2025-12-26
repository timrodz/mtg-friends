export type RootStackParamList = {
  Login: undefined;
  TournamentList: undefined;
  TournamentCreate: { id?: number };
  TournamentDetail: { id: number };
  TournamentEdit: { id: number };
  ParticipantCreate: { tournamentId: number };
  ParticipantEdit: { tournamentId: number; participant: any };
  RoundDetail: { tournamentId: number; roundNumber: number };
};
