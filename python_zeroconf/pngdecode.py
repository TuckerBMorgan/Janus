import io
from PIL import Image
import numpy as np

searchingCharacters = [b'E', b'N', b'D',b'P',b'N',b'G']

flagCharacter = 0
numberOfPngs = 0

def advanceSearchingCharacter(currentIndex):
    if currentIndex + 1 == len(searchingCharacters):
        return -1
    else:
        return currentIndex + 1
 
with open("hdr19201080.png", "rb") as f:
    byte = f.read(1)
    png_array = []
    while byte != b"":
        png_array.append(byte)
        if byte is searchingCharacters[flagCharacter]:
            flagCharacter = advanceSearchingCharacter(flagCharacter)
            if flagCharacter is -1:#we have our full png DEAL WITH IT
                numberOfPngs += 1
                with open("Images/" + str(numberOfPngs) + ".png", 'wb') as l:
                    for item in png_array:
                        l.write(item)
                png_array = []
                flagCharacter = 0
        else:
            flagCharacter = 0
        byte = f.read(1)

