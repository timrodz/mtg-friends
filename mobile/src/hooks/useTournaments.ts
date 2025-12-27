import {
  useInfiniteQuery,
  useMutation,
  useQuery,
  useQueryClient,
} from "@tanstack/react-query";
import {
  createTournament,
  fetchTournament,
  fetchTournaments,
  updateTournament,
} from "../api/client";
import { TournamentRequest } from "../api/types";

const TOURNAMENTS_LIMIT = 10;

export const useTournaments = () => {
  return useInfiniteQuery({
    queryKey: ["tournaments"],
    queryFn: ({ pageParam }) => fetchTournaments(pageParam, TOURNAMENTS_LIMIT),
    initialPageParam: 1,
    getNextPageParam: (lastPage, allPages) => {
      if (!lastPage.data || lastPage.data.length < TOURNAMENTS_LIMIT)
        return undefined;
      return allPages.length + 1;
    },
  });
};

export const useTournament = (id: number) => {
  return useQuery({
    queryKey: ["tournament", id],
    queryFn: () => fetchTournament(id),
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
    mutationFn: ({ id, data }: { id: number; data: TournamentRequest }) =>
      updateTournament(id, data),
    onSuccess: (data, variables) => {
      queryClient.invalidateQueries({ queryKey: ["tournaments"] });
      queryClient.invalidateQueries({ queryKey: ["tournament", variables.id] });
    },
  });
};
