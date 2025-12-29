import { useMutation, useQueryClient } from "@tanstack/react-query";
import {
  createParticipant,
  deleteParticipant,
  updateParticipant,
} from "../api/client";
import { ParticipantRequest } from "../api/types";

export const useCreateParticipant = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({
      tournamentId,
      data,
    }: {
      tournamentId: number;
      data: ParticipantRequest;
    }) => createParticipant(tournamentId, data),
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
      data: ParticipantRequest;
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
