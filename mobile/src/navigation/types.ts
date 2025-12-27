import {
  ParticipantRequest,
  ParticipantResponse,
  ParticipantType,
} from "../api/types";

export type RootStackParamList = {
  Login: undefined;
  TournamentList: undefined;
  TournamentCreate: { id?: number };
  TournamentDetail: { id: number };
  TournamentEdit: { id: number };
  ParticipantCreate: { tournamentId: number };
  ParticipantEdit: { tournamentId: number; participant: ParticipantType };
  RoundDetail: { tournamentId: number; roundNumber: number };
};
