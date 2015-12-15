local ffmpeg = require('ffmpeg')

describe("ffmpeg", function()
  describe("Video", function()
    local video

    before_each(function()
      video = M.new('./test/data/centaur_1.mpg')
    end)

    describe(":duration", function()
      it("should return video duration in seconds", function()
        local expected = 14.0
        local actual = video:duration()
        assert.is_near(expected, actual, 1.0);
      end)
    end)

    describe(":pixel_format_name", function()
      it("should return pixel format name as a string", function()
        local expected = 'yuv420p'
        local actual = video:pixel_format_name()
        assert.are.same(expected, actual);
      end)
    end)

    describe(":each_frame", function()
      it("should call callback function once per frame", function()
        local i = 0
        video:each_frame(function() i = i + 1 end)
        assert.are.same(418, i);
      end)
    end)

    -- it("ascii video fun", function()
    --   local i = 0
    --   io.write('\027[H\027[2J')
    --   video:each_frame(function(frame)
    --     io.write(video:image_to_ascii(frame))
    --     -- os.execute('sleep 1')
    --     i = i + 1
    --   end)
    -- end)
  end)
end)
