module HuffmanTree ( encode, decode) where

import Data.List as List (sortBy, nub)
import qualified Data.Map as Map

data BinaryTree a = EmptyTree | Node { root  :: a,
                                       left  :: (BinaryTree a),
                                       right :: (BinaryTree a)
                                     } deriving (Show, Eq)

type Code            = String
type CharFrequency   = (Char, Int)
type CharFrequencies = [CharFrequency]
type HuffmanTree     = BinaryTree CharFrequency

makeLeaf ::  CharFrequency -> HuffmanTree
makeLeaf root = (Node root EmptyTree EmptyTree)

isLeaf :: HuffmanTree -> Bool
isLeaf (Node root EmptyTree EmptyTree) = True
isLeaf                              _  = False

emptyTree :: HuffmanTree -> Bool
emptyTree EmptyTree = True
emptyTree         _ = False

-- Get character associated with root:
char :: HuffmanTree -> Char
char = fst . root

-- Get frequency associated with root:
frequency :: HuffmanTree -> Int
frequency = snd . root

-- Define sorting over Huffman Trees based on their char frequencies:
charFrequency :: HuffmanTree -> HuffmanTree -> Ordering
charFrequency (Node (_, x) _ _) (Node (_, y) _ _)
  | x < y     = LT
  | x > y     = GT
  | otherwise = EQ

-- Obtain file`s characters` frequencies:
-- Example: contentsFrequency "abracadabra" -> [('a',5),('b',2),('r',2),('c',1),('d',1)]
contentsFrequency :: String -> [CharFrequency]
contentsFrequency contents = nub $ map (\x -> (x, count x contents)) contents
  where count x l = sum $ map (\y -> if y == x then 1 else 0) l

-- Make each (Char,Frequency) pair a leaf in the Huffman Tree:
makeLeaves :: CharFrequencies -> [HuffmanTree]
makeLeaves = map (\(x,y) -> makeLeaf (x, y))

-- Merge two trees together, so that their frequencies sum up:
mergeTrees :: HuffmanTree -> HuffmanTree -> HuffmanTree
mergeTrees  left right = Node (' ', frequenciesSum) left right
  where frequenciesSum = frequency left + frequency right

-- Construct HuffmanTree based on file`s unique characters and their respective frequencies:
constructHuffmanTree :: CharFrequencies -> HuffmanTree
constructHuffmanTree input    = construct $ makeLeaves input
  where construct []          = EmptyTree
        construct [tree]      = tree
        construct input       = construct updated
          where sorted        = sortBy charFrequency input 
                smallestTrees = take 2 sorted 
                rightTree     = head smallestTrees
                leftTree      = head $ tail smallestTrees
                merged        = mergeTrees rightTree leftTree
                removed       = drop 2 sorted
                updated       = merged : removed


-- Generate unique binary indentification codes per file`s unique characters:
binaryCodes :: HuffmanTree -> [(Char, Code)]
binaryCodes huffmanTree = generateCodes huffmanTree ""
  where generateCodes huffmanTree path
          | isLeaf huffmanTree = [(char huffmanTree, path)]
          | otherwise          = generateCodes (left huffmanTree) (path ++ "0")
                                 ++ generateCodes (right huffmanTree) (path ++ "1")

-- Transform file`s contents to encoded sequence of 1`s and 0`s (Huffman Algorithm):
-- Example: encodeContents "abracadabra" -> ("01111001100011010111100", <tree>),
--          where <tree> is a valid Huffman Tree.
encode :: String -> (Code, HuffmanTree)
encode content            = (encoded content, huffmanTree)
  where codes             = Map.fromList $ binaryCodes $ huffmanTree
        encoded           = concat . Prelude.map (\char -> getValue (Map.lookup char codes))
        huffmanTree       = constructHuffmanTree $ contentsFrequency content
        getValue (Just a) = a

-- Decode a Huffman Tree in order to obtain file`s initial contents:
decode :: (Code, HuffmanTree) -> String
decode (code, huffmanTree) = decodeTree code huffmanTree
  where decodeTree [x] tree   = if x == '0' then [char $ left tree] else [char $ right tree]
        decodeTree code@(x:xs) tree =
          case x of '0' -> if isLeaf tree
                           then char tree : decodeTree code huffmanTree
                           else decodeTree xs (left tree)
                    '1' -> if isLeaf tree
                           then char tree : decodeTree code huffmanTree
                           else decodeTree xs (right tree)