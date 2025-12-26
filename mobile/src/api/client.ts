import axios, { InternalAxiosRequestConfig } from "axios";
import { useAuthStore } from "../store/authStore";
import type { components } from "./generated/schema";
import {
  LoginResponse,
  PairingResponse,
  ParticipantResponse,
  RoundResponse,
  TournamentResponse,
  TournamentArrayResponse,
} from "./types";

const API_URL = process.env.EXPO_PUBLIC_API_URL;

const axiosInstance = axios.create({
  baseURL: API_URL,
  headers: {
    "Content-Type": "application/json",
  },
});

axiosInstance.interceptors.request.use((config: InternalAxiosRequestConfig) => {
  const token = useAuthStore.getState().token;
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

axiosInstance.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      if (!error.config.url?.includes("/login")) {
        useAuthStore.getState().logout();
      }
    }
    return Promise.reject(error);
  }
);

// General
export const login = async (email: string, password: string) => {
  const response = await axiosInstance.post<LoginResponse>("/login", {
    email,
    password,
  });
  return response.data;
};

// Tournaments
export const fetchTournaments = async (page = 1, limit = 10) => {
  const response = await axiosInstance.get<TournamentArrayResponse>(
    "/tournaments",
    {
      params: { page, limit },
    }
  );
  return response.data;
};

export const fetchTournament = async (id: string) => {
  const response = await axiosInstance.get<TournamentResponse>(
    `/tournaments/${id}`
  );
  return response.data;
};

export const createTournament = async (
  data: components["schemas"]["TournamentRequest"]["tournament"]
) => {
  const response = await axiosInstance.post<TournamentResponse>(
    "/tournaments",
    {
      tournament: data,
    }
  );
  return response.data;
};

export const updateTournament = async (
  id: number,
  data: components["schemas"]["TournamentRequest"]["tournament"]
) => {
  const response = await axiosInstance.put<TournamentResponse>(
    `/tournaments/${id}`,
    {
      tournament: data,
    }
  );
  return response.data;
};

// Participants
export const createParticipant = async (
  tournamentId: number,
  data: components["schemas"]["ParticipantRequest"]["participant"]
) => {
  const response = await axiosInstance.post<ParticipantResponse>(
    `/tournaments/${tournamentId}/participants`,
    { participant: data }
  );
  return response.data;
};

export const updateParticipant = async (
  tournamentId: number,
  participantId: number,
  data: components["schemas"]["ParticipantRequest"]["participant"]
) => {
  const response = await axiosInstance.put<ParticipantResponse>(
    `/tournaments/${tournamentId}/participants/${participantId}`,
    { participant: data }
  );
  return response.data;
};

export const deleteParticipant = async (
  tournamentId: number,
  participantId: number
) => {
  // 204 response has no content, so we just return true or verify status
  const response = await axiosInstance.delete(
    `/tournaments/${tournamentId}/participants/${participantId}`
  );
  if (response.status === 204) return { data: true };
  return response.data;
};

// Rounds
export const fetchRound = async (tournamentId: number, number: number) => {
  const response = await axiosInstance.get<RoundResponse>(
    `/tournaments/${tournamentId}/rounds/${number}`
  );
  return response.data;
};

export const createRound = async (tournamentId: number) => {
  const response = await axiosInstance.post<RoundResponse>(
    `/tournaments/${tournamentId}/rounds`
  );
  return response.data;
};

export const updateRound = async (
  tournamentId: number,
  roundNumber: number,
  results: components["schemas"]["RoundResultsRequest"]["results"]
) => {
  const response = await axiosInstance.put<RoundResponse>(
    `/tournaments/${tournamentId}/rounds/${roundNumber}`,
    { results }
  );
  return response.data;
};

// Pairings
export const updatePairing = async (
  tournamentId: number,
  roundId: number,
  pairingId: number,
  data: components["schemas"]["PairingRequest"]["pairing"]
) => {
  const response = await axiosInstance.put<PairingResponse>(
    `/tournaments/${tournamentId}/rounds/${roundId}/pairings/${pairingId}`,
    { pairing: data }
  );
  return response.data;
};
