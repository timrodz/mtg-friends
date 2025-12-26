import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { createRound, fetchRound, updateRound } from "../api/client";
import { RoundResultsRequest } from "../api/types";

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
      results: RoundResultsRequest;
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
