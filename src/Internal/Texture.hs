module Internal.Texture
  ( ImageTexture (..)
  , TextureAnimation (..)
  , noTexture
  , loadTexture
  ) where

import Graphics.UI.SDL
import Graphics.UI.SDL.Image
import Graphics.Rendering.OpenGL
import System.IO.Unsafe

data ImageTexture = ImageTexture !TextureObject !GLfloat !GLfloat
  deriving (Eq)

data TextureAnimation = TA
  { texture :: Maybe ImageTexture
  , textureDivs :: (Int, Int)
  , frames :: [(Int, Int)]
  } deriving (Eq)

noTexture = TA Nothing (0,0) []

loadTexture :: FilePath -> ImageTexture
loadTexture fileName = unsafePerformIO $ do
  putStrLn "WARNING: Unsafe texture loading."
  -- load to SDL Surface
  srcSurface <- load fileName
  let w = surfaceGetWidth srcSurface
      h = surfaceGetHeight srcSurface
  -- create pow2 SDL Surface
  let size = ceilingPow2 $ max w h
      sizeGL = fromIntegral size
  newSurface <- createRGBSurfaceEndian [] size size 32
  True <- blitSurface srcSurface Nothing newSurface Nothing
  freeSurface srcSurface
  pixels <- surfaceGetPixels newSurface
  let pixelData = PixelData RGBA UnsignedByte pixels
  -- gen OpenGL Texture
  [tex] <- genObjectNames 1
  textureBinding Texture2D $= Just tex
  textureFilter Texture2D $=! ((Linear', Nothing), Linear')
  texImage2D Nothing NoProxy 0 RGBA' (TextureSize2D sizeGL sizeGL) 0 pixelData
  return $ ImageTexture tex (w `fdiv` size) (h `fdiv` size)

fdiv x y = (realToFrac x) / (realToFrac y)

ceilingPow2 :: Integral a => a -> a
ceilingPow2 x = head $ dropWhile (< x) [2^n | n <- [0..]]
