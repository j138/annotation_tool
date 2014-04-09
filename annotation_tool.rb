#!/usr/bin/env ruby

require 'opencv'
include OpenCV

if ARGV.size != 1
  puts 'Usage: % ruby annotation_tool.rb ./IMG_DIR/'
  img_path = './img/'
else
  img_path = ARGV[0]
end

# カスケードを設置しているなら読み込んで囲む
casscade_path = './cascade.xml'

# ファイルから読み込んだアノテーション管理
class AnnotationManager
  attr_accessor :annotations

  def initialize(save_file_path)
    @annotations = {}

    # 保存する予定のannotations.txt
    @file_path = save_file_path

    open(@file_path) do |f|
      return unless File.exist? @file_path

      f.each do | line |
        v = line.split(' ')

        # ファイル名をキーにリストを管理
        loop_times = v[1].to_i

        loop_times.times do |i|
          key = v[0]
          x = v[2 + i * 4].to_i
          y = v[3 + i * 4].to_i
          w = v[4 + i * 4].to_i
          h = v[5 + i * 4].to_i

          @annotations[key] = [] unless @annotations.key? key
          @annotations[key].push(start: [x, y], stop: [x + w, y + h])
        end
      end
    end
  end

  def get(key)
    @annotations.key?(key) ? @annotations[key] : []
  end

  def set(key, val)
    @annotations[key] = val
  end

  def save
    open(@file_path, 'w') do |f|
      @annotations.each do |k, v|
        rect_map = ''
        count = 0

        v.each do |rect|
          x1 = rect[:start][0]
          y1 = rect[:start][1]
          x2 = rect[:stop][0]
          y2 = rect[:stop][1]

          w = (x2 - x1)
          h = (y2 - y1)

          x = w > 0 ? x1 : x2
          y = h > 0 ? y1 : y2

          rect_map += format('%s %s %s %s ', x, y, w.abs, h.abs)
          count += 1
        end

        f.write format('%s %s %s' + "\n", k, count, rect_map) if count > 0
      end
    end
  end
end

annotation_mngr = AnnotationManager.new 'annotation.txt'

def draw_canvas(canvas, annotations)
  annotations.each do |annotation|
    canvas.rectangle!(
      CvPoint.new(annotation[:start][0], annotation[:start][1]),
      CvPoint.new(annotation[:stop][0], annotation[:stop][1]),
      color: CvColor::Red
    )
  end
  canvas
end

def start_annotate(window, canvas, file_path, annotations, annotation_mngr)
  canvas = draw_canvas(canvas, annotations)
  window.show canvas

  # 線の色と太さ
  opt = {
    color: CvColor::Black,
    thickness: 1
  }

  point = nil
  start_point = nil
  stop_point = nil

  window.on_mouse do | m |
    case m.event
    when :left_button_down
      canvas.line!(m, m, opt)
      point = m
      start_point = m

    when :move
      if m.left_button?
        canvas.line!(point, m, opt) if point
        point = m
      end

    when :left_button_up
      stop_point = m
      point = nil

      if (start_point.x - stop_point.x).abs > 10 && (start_point.x - stop_point.x).abs > 10
        annotations.push(start: [start_point.x, start_point.y], stop: [stop_point.x, stop_point.y])
      end
      canvas = draw_canvas(canvas, annotations)

    when :right_button_down # マウスの右ボタンで塗りつぶし
      canvas.flood_fill!(m, opt[:color])
    end

    window.show canvas
  end

  loop do
    key = GUI.wait_key
    next if key < 0 || key > 255

    case key.chr
    when "\e" # ESCキーで終了
      exit
    when "\r", "\n"
      return annotations
    when '1'..'9'
      opt[:thickness] = key.chr.to_i
    when 'd'
      annotations.pop
      canvas = draw_canvas(IplImage.load(file_path), annotations)
      window.show canvas
    when 'x'
      # 重複チェックなし
      File.open('ng_list.txt', 'a')  { |file| file.puts file_path }
    when 's'
      annotation_mngr.save
      puts 'saved'
    end
  end

  annotations
end

window = GUI::Window.new('detect face')

Dir.entries(img_path).each do | f |
  next unless f =~ /jpg|png|jpeg|txt|damaged/
  file_path = img_path + f
  canvas = IplImage.load(file_path)

  if File.exist? casscade_path
    cscd = OpenCV::CvHaarClassifierCascade.load casscade_path
    cscd.detect_objects(canvas.to_CvMat) do |rect|
      canvas.rectangle!(rect.top_left, rect.bottom_right, color: CvColor::Blue)
    end
  end

  window.show canvas
  annotations = annotation_mngr.get(file_path)
  ret_annotations = start_annotate(window, canvas, file_path, annotations, annotation_mngr)
  annotation_mngr.set(file_path, ret_annotations)
end

annotation_mngr.save
GUI::Window.destroy_all
