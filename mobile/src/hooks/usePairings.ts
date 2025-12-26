import { useMutation, useQueryClient } from "@tanstack/react-query";
import { updatePairing } from "../api/client";

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
