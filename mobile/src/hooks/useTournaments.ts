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
