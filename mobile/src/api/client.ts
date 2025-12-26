import { useAuthStore } from "../store/authStore";
import { QueryClient } from "@tanstack/react-query";

export const queryClient = new QueryClient();

// Use localhost for iOS simulator, or specific IP for physical device
// For Android Emulator, use 10.0.2.2 usually, but strict localhost might work with adb reverse
// Stick to localhost as verified working in previous steps for now.
export const API_URL = "http://localhost:4000/api";

const getHeaders = () => {
  const token = useAuthStore.getState().token;
  return {
    "Content-Type": "application/json",
    Authorization: token ? `Bearer ${token}` : "",
  };
};

const handleResponse = async (response: Response) => {
  if (response.status === 401) {
    useAuthStore.getState().logout();
    throw new Error("Session expired");
  }
  if (!response.ok) {
    const errorBody = await response.text();
    throw new Error(errorBody || "API Request Failed");
  }
  return response.json();
};

export const login = async (email: string, password: string) => {
  const response = await fetch(`${API_URL}/login`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email, password }),
  });
  return handleResponse(response);
};

export const fetchTournaments = async (page = 1, limit = 10) => {
  const queryParams = new URLSearchParams({
    page: page.toString(),
    limit: limit.toString(),
  });
  const response = await fetch(
    `${API_URL}/tournaments?${queryParams.toString()}`,
    {
      headers: getHeaders(),
    }
  );
  return handleResponse(response);
};

export const fetchTournament = async (id: string) => {
  const response = await fetch(`${API_URL}/tournaments/${id}`, {
    headers: getHeaders(),
  });
  return handleResponse(response);
};

export const createTournament = async (data: any) => {
  const response = await fetch(`${API_URL}/tournaments`, {
    method: "POST",
    headers: getHeaders(),
    body: JSON.stringify({ tournament: data }),
  });
  return handleResponse(response);
};

export const updateTournament = async (id: number, data: any) => {
  const response = await fetch(`${API_URL}/tournaments/${id}`, {
    method: "PUT",
    headers: getHeaders(),
    body: JSON.stringify({ tournament: data }),
  });
  return handleResponse(response);
};

// Participants
export const createParticipant = async (tournamentId: number, data: any) => {
  const response = await fetch(
    `${API_URL}/tournaments/${tournamentId}/participants`,
    {
      method: "POST",
      headers: getHeaders(),
      body: JSON.stringify({ participant: data }),
    }
  );
  return handleResponse(response);
};

export const updateParticipant = async (
  tournamentId: number,
  participantId: number,
  data: any
) => {
  const response = await fetch(
    `${API_URL}/tournaments/${tournamentId}/participants/${participantId}`,
    {
      method: "PUT",
      headers: getHeaders(),
      body: JSON.stringify({ participant: data }),
    }
  );
  return handleResponse(response);
};

export const fetchRound = async (tournamentId: number, number: number) => {
  const response = await fetch(
    `${API_URL}/tournaments/${tournamentId}/rounds/${number}`,
    {
      headers: getHeaders(),
    }
  );
  return handleResponse(response);
};

export const deleteParticipant = async (
  tournamentId: number,
  participantId: number
) => {
  const response = await fetch(
    `${API_URL}/tournaments/${tournamentId}/participants/${participantId}`,
    {
      method: "DELETE",
      headers: getHeaders(),
    }
  );
  if (response.status === 204) return { data: true };
  return handleResponse(response);
};

// Rounds
export const createRound = async (tournamentId: number) => {
  const response = await fetch(
    `${API_URL}/tournaments/${tournamentId}/rounds`,
    {
      method: "POST",
      headers: getHeaders(),
    }
  );
  return handleResponse(response);
};

export const updateRound = async (
  tournamentId: number,
  roundNumber: number,
  results: any[]
) => {
  const response = await fetch(
    `${API_URL}/tournaments/${tournamentId}/rounds/${roundNumber}`,
    {
      method: "PUT",
      headers: getHeaders(),
      body: JSON.stringify({ results }),
    }
  );
  return handleResponse(response);
};
