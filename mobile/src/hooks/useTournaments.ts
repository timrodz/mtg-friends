import {
  useInfiniteQuery,
  useMutation,
  useQuery,
  useQueryClient,
} from "@tanstack/react-query";
import {
  fetchTournaments,
  fetchTournament,
  createTournament,
  updateTournament,
  createParticipant,
  updateParticipant,
  deleteParticipant,
  createRound,
  fetchRound,
  updateRound,
  updatePairing,
} from "../api/client";

export const useTournaments = () => {
  return useInfiniteQuery({
    queryKey: ["tournaments"],
    queryFn: ({ pageParam }) => fetchTournaments(pageParam, 10),
    initialPageParam: 1,
    getNextPageParam: (lastPage, allPages) => {
      // API returns { data: [...items] }
      // If lastPage data is less than limit (10), we are done.
      if (!lastPage.data || lastPage.data.length < 10) return undefined;
      return allPages.length + 1;
    },
  });
};

export const useTournament = (id: number) => {
  return useQuery({
    queryKey: ["tournament", id],
    queryFn: () => fetchTournament(id.toString()),
    enabled: !!id,
  });
};

export const useCreateTournament = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: createTournament,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["tournaments"] });
    },
  });
};

export const useUpdateTournament = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, data }: { id: number; data: any }) =>
      updateTournament(id, data),
    onSuccess: (data, variables) => {
      queryClient.invalidateQueries({ queryKey: ["tournaments"] });
      queryClient.invalidateQueries({ queryKey: ["tournament", variables.id] });
    },
  });
};

export const useCreateParticipant = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ tournamentId, data }: { tournamentId: number; data: any }) =>
      createParticipant(tournamentId, data),
    onSuccess: (data, variables) => {
      queryClient.invalidateQueries({
        queryKey: ["tournament", variables.tournamentId],
      });
    },
  });
};

export const useUpdateParticipant = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({
      tournamentId,
      participantId,
      data,
    }: {
      tournamentId: number;
      participantId: number;
      data: any;
    }) => updateParticipant(tournamentId, participantId, data),
    onSuccess: (data, variables) => {
      queryClient.invalidateQueries({
        queryKey: ["tournament", variables.tournamentId],
      });
    },
  });
};

export const useDeleteParticipant = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({
      tournamentId,
      participantId,
    }: {
      tournamentId: number;
      participantId: number;
    }) => deleteParticipant(tournamentId, participantId),
    onSuccess: (data, variables) => {
      queryClient.invalidateQueries({
        queryKey: ["tournament", variables.tournamentId],
      });
    },
  });
};

export const useCreateRound = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (tournamentId: number) => createRound(tournamentId),
    onSuccess: (data, tournamentId) => {
      queryClient.invalidateQueries({
        queryKey: ["tournament", tournamentId],
      });
    },
  });
};

export const useRound = (tournamentId: number, roundNumber: number) => {
  return useQuery({
    queryKey: ["round", tournamentId, roundNumber],
    queryFn: () => fetchRound(tournamentId, roundNumber),
    enabled: !!tournamentId && roundNumber !== undefined && roundNumber >= 0,
  });
};

export const useUpdateRound = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({
      tournamentId,
      roundNumber,
      results,
    }: {
      tournamentId: number;
      roundNumber: number;
      results: any[];
    }) => updateRound(tournamentId, roundNumber, results),
    onSuccess: (data, variables) => {
      queryClient.invalidateQueries({
        queryKey: ["round", variables.tournamentId, variables.roundNumber],
      });
      queryClient.invalidateQueries({
        queryKey: ["tournament", variables.tournamentId],
      });
    },
  });
};

export const useUpdatePairing = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({
      tournamentId,
      roundId,
      pairingId,
      data,
    }: {
      tournamentId: number;
      roundId: number;
      pairingId: number;
      data: any;
    }) => updatePairing(tournamentId, roundId, pairingId, data),
    onSuccess: (data, variables) => {
      queryClient.invalidateQueries({
        queryKey: ["round", variables.tournamentId],
      });
      queryClient.invalidateQueries({
        queryKey: ["tournament", variables.tournamentId],
      });
    },
  });
};
