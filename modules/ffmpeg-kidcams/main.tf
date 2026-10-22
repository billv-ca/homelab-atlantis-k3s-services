resource "kubernetes_namespace_v1" "namespace" {
  metadata {
    name = "ffmpeg"
  }
}

resource "kubernetes_deployment_v1" "ffmpeg_kidcams" {
  metadata {
    name      = "ffmpeg-kidcams"
    namespace = kubernetes_namespace_v1.namespace.metadata.0.name
    labels = {
      app = "ffmpeg-kidcams"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "ffmpeg-kidcams"
      }
    }

    template {
      metadata {
        labels = {
          app = "ffmpeg-kidcams"
        }
      }

      spec {
        container {
          name  = "ffmpeg"
          image = "linuxserver/ffmpeg:latest"

          command = ["/bin/sh", "-c"]
          args = [
            <<-EOT
            ffmpeg -loglevel info -stats \
                   -fflags +genpts+igndts -correct_ts_overflow 1 -use_wallclock_as_timestamps 1 \
                   -probesize 32M -analyzeduration 32M \
                   -hwaccel vaapi -hwaccel_output_format vaapi -rtsp_transport tcp -c:v h264 -i "rtsp://homeassistant:homeassistant@10.203.0.6:554/stream1" \
                   -probesize 32M -analyzeduration 32M \
                   -hwaccel vaapi -hwaccel_output_format vaapi -rtsp_transport tcp -c:v h264 -i "rtsp://homeassistant:homeassistant@10.203.0.3:554/stream1" \
                   -probesize 32M -analyzeduration 32M \
                   -hwaccel vaapi -hwaccel_output_format vaapi -rtsp_transport tcp -c:v h264 -i "rtsp://homeassistant:homeassistant@10.202.0.26:554/stream1" \
                   -filter_complex "
                     [0:v]fps=fps=15[cam1_fixed];
                     [1:v]scale_vaapi=w=960:h=540,fps=fps=15[cam2];
                     [2:v]scale_vaapi=w=960:h=540,fps=fps=15[cam3];
                     [cam1_fixed][cam2]overlay_vaapi=x=960:y=0[tmp1];
                     [tmp1][cam3]overlay_vaapi=x=960:y=540[v_out];
                     [0:a]asetpts=N/SR/TB[a_fixed]
                   " \
                   -map "[v_out]" -c:v h264_vaapi -r 15 -g 30 -b:v 2.5M -maxrate 3.5M -bufsize 1M -async_depth 4 \
                   -map "[a_fixed]" -c:a aac -b:a 128k -ac 2 \
                   -f rtsp rtsp://10.206.2.7:8554/grid 2>&1
            EOT
          ]

          volume_mount {
            name       = "dri"
            mount_path = "/dev/dri"
          }

          resources {
            requests = {
              "gpu.intel.com/i915" = "1"
            }
            limits = {
              "gpu.intel.com/i915" = "1"
            }
          }
        }

        volume {
          name = "dri"
          host_path {
            path = "/dev/dri"
            type = "Directory"
          }
        }
      }
    }
  }
}
