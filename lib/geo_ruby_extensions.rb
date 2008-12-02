module GeoRuby
  module SimpleFeatures
    class Point
      def self.from_point(point, brng, dist)
        deg_to_rad = 0.0174532925199433
        a = 6378137; b = 6356752.3142;  f = 1/298.257223563;  # WGS-84 ellipsoid
        a_squared = a*a; b_squared = b*b;
        s = dist
        alpha1 = brng * deg_to_rad
        sinAlpha1 = Math.sin(alpha1)
        cosAlpha1 = Math.cos(alpha1)
        
        tanU1 = (1-f) * Math.tan(point.lat * deg_to_rad)
        cosU1 = 1 / Math.sqrt((1 + tanU1*tanU1))
        sinU1 = tanU1*cosU1
        sigma1 = Math.atan2(tanU1, cosAlpha1)
        sinAlpha = cosU1 * sinAlpha1
        cosSqAlpha = 1 - sinAlpha*sinAlpha;
        uSq = cosSqAlpha * (a*a - b*b) / (b*b)
        a1 = 1 + uSq/16384*(4096+uSq*(-768+uSq*(320-175*uSq)))
        b1 = uSq/1024 * (256+uSq*(-128+uSq*(74-47*uSq)))

        sigma = s / (b*a1 )
        sigmaP = 2*Math::PI
        
        while ((sigma-sigmaP).abs > 1e-12) do
          cos2SigmaM = Math.cos(2*sigma1 + sigma)
          sinSigma = Math.sin(sigma)
          cosSigma = Math.cos(sigma)
          deltaSigma = b1*sinSigma*(cos2SigmaM+b1/4*(cosSigma*(-1+2*cos2SigmaM*cos2SigmaM)-
            b1/6*cos2SigmaM*(-3+4*sinSigma*sinSigma)*(-3+4*cos2SigmaM*cos2SigmaM)))
          sigmaP = sigma
          sigma = (s / (b*a1)) + deltaSigma
        end

        tmp = (sinU1*sinSigma) - (cosU1*cosSigma*cosAlpha1)
        lat2 = Math.atan2(sinU1*cosSigma + cosU1*sinSigma*cosAlpha1,
            (1-f)*Math.sqrt(sinAlpha*sinAlpha + tmp*tmp))
        lambda1 = Math.atan2(sinSigma*sinAlpha1, cosU1*cosSigma - sinU1*sinSigma*cosAlpha1)
        c = f/16*cosSqAlpha*(4+f*(4-3*cosSqAlpha))
        l = lambda1 - ((1-c) * f * sinAlpha * (sigma + c*sinSigma*(cos2SigmaM+c*cosSigma*(-1+2*cos2SigmaM*cos2SigmaM))))

        revAz = Math.atan2(sinAlpha, -tmp);  # final bearing

        dest_point= new(point.srid)
        dest_point.set_x_y(point.lon+l / deg_to_rad, lat2 / deg_to_rad)
      end
    end
  end
end


