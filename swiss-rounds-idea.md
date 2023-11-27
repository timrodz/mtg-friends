SWISS ROUNDS - 6 PLAYER TOURNAMENT

Round 0:

1. Randomize all players
2. Pick players in order

Round -3:

- Assign values where (1) represents a player you've played with before, (0) a player you haven't
- For every player, create a list of possible opponents, sort from lowest to highest

==== TEST

Round 0:
pod 1: A B C D
pod 2: E F G H
pod 3: I J K L
pod 4: M N O P

round 1:
A = [B C D] {E F G H I J K L M N O P}
B = [A C D] {E F G H I J K L M N O P}
C = [A B D] {E F G H I J K L M N O P}
D = [A B C] {E F G H I J K L M N O P}

E = [F G H] {A B C D I J K L M N O P}
F = [E G H] {A B C D I J K L M N O P}
G = [E F H] {A B C D I J K L M N O P}
H = [E F G] {A B C D I J K L M N O P}

I = [J K L] {A B C D E F G H M N O P}
J = [I K L] {A B C D E F G H M N O P}
K = [I J L] {A B C D E F G H M N O P}
L = [I J K] {A B C D E F G H M N O P}

M = [N O P] {A B C D E F G H I J K L}
N = [M O P] {A B C D E F G H I J K L}
O = [M N P] {A B C D E F G H I J K L}
P = [M N O] {A B C D E F G H I J K L}

pod 1: A E I M
pod 2: B F J N
pod 3: C G K O
pod 4: D H L P

round 2:
A = [B C D E I M] {F G H J K L N O P}
B = [A C D F J N] {E G H I K L M O P}
C = [A B D G K O] {E F H I J L M N P}
D = [A B C H L P] {E F G I J K M N O}

E = [F G H] {A B C D I J K L M N O P}
F = [E G H] {A B C D I J K L M N O P}
G = [E F H] {A B C D I J K L M N O P}
H = [E F G] {A B C D I J K L M N O P}

I = [J K L] {A B C D E F G H M N O P}
J = [I K L] {A B C D E F G H M N O P}
K = [I J L] {A B C D E F G H M N O P}
L = [I J K] {A B C D E F G H M N O P}

M = [N O P] {A B C D E F G H I J K L}
N = [M O P] {A B C D E F G H I J K L}
O = [M N P] {A B C D E F G H I J K L}
P = [M N O] {A B C D E F G H I J K L}

pod 1: A E I M
pod 2: B F J N
pod 3: C G K O
pod 4: D H L P
