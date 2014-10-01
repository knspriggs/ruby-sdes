# S-DES in Ruby
# inspiration: http://jhafranco.com/2012/02/10/simplified-des-implementation-in-python/
# author: Kristian Spriggs

$keyLength = 10
$subKeyLength = 8
$dataLength = 8
$fLength = 4

$ipTable = [2, 6, 3, 1, 4, 8, 5, 7]
$fpTable = [4, 1, 3, 5, 7, 2, 8, 6]

$p10Table = [3, 5, 2, 7, 4, 10, 1, 9, 8, 6]
$p8Table = [6, 3, 7, 4, 8, 5, 10, 9]

$epTable = [4, 1, 2, 3, 2, 3, 4, 1]
$s0Table = [1, 0, 3, 2, 3, 2, 1, 0, 0, 2, 1, 3, 3, 1, 3, 2]
$s1Table = [0, 1, 2, 3, 2, 0, 1, 3, 3, 0, 1, 0, 2, 1, 0, 3]
$p4Table = [2, 4, 3, 1]

def perm(inputByte, permTable)
  outputByte = 0
  permTable.each_with_index do |element, index|
    if index >= element
      outputByte |= (inputByte & (128 >> (element -1))) >> (index - (element - 1))
    else
      outputByte |= (inputByte & (128 >> (element - 1))) << ((element - 1) - index)
    end
  end
  return outputByte
end

def ip(inputByte)
  perm(inputByte, $ipTable)
end

def fp(inputByte)
  perm(inputByte, $fpTable)
end

def swapNibbles(inputByte)
  (inputByte << 4 | inputByte >> 4) & 0xff
end

def leftShift(key)
  tmp = []
  for ind in 1..$keyLength
    tmp.push(key[ind.modulo 10])
  end
  return tmp
end

def keygen(key)
  keyList = []
  for i in (0..10).to_a.reverse
    keyList.push((key & 1 << i) >> i)
  end
  permKeyList = []
  $p10Table.each_with_index do |element, index|
    permKeyList.push(keyList[element-1])
  end
  shiftedOnceKey = leftShift(permKeyList)
  shiftedTwiceKey = leftShift(leftShift(shiftedOnceKey))
  subKey1 = 0
  subKey2 = 0
  $p8Table.each_with_index do |element, index|
    subKey1 = subKey1 + (128 >> index) * shiftedOnceKey[element-1]
    subKey2 = subKey2 + (128 >> index) * shiftedTwiceKey[element-1]
  end
  return subKey1, subKey2
end

def f(sKey, rightNibble)
  aux = sKey ^ perm(swapNibbles(rightNibble), $epTable)
  index1 = ((aux & 0x80) >> 4) + ((aux & 0x40) >> 5) + ((aux & 0x20) >> 5) + ((aux & 0x10) >> 2)
  index2 = ((aux & 0x08) >> 0) + ((aux & 0x04) >> 1) + ((aux & 0x02) >> 1) + ((aux & 0x01) << 2)
  sboxOutputs = swapNibbles(($s0Table[index1] << 2) + $s1Table[index2])
  return perm(sboxOutputs, $p4Table)
end

def fk(subKey, inputData)
  leftNibble = inputData & 0xf0
  rightNibble = inputData & 0x0f
  return (leftNibble ^ f(subKey, rightNibble)) | rightNibble
end

def encrypt(key, plaintext)
  data = fk(keygen(key)[0], ip(plaintext))
  return fp(fk(keygen(key)[1], swapNibbles(data)))
end

def decrypt(key, ciphertext)
  data = fk(keygen(key)[1], ip(ciphertext))
  return fp(fk(keygen(key)[0], swapNibbles(data)))
end


if __FILE__ == $0
  puts "Encrypt #{0b10101010.to_s(2)} with k=#{0b0000000000.to_s(2)}" + encrypt(0b0000000000, 0b10101010).to_s(2) # 0b00010001
  puts "Decrypt #{0b00010001.to_s(2)} with k=#{0b0000000000.to_s(2)}" + decrypt(0b0000000000, 0b00010001).to_s(2) # 0b10101010
end
