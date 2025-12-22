# 批量下载B站视频脚本
# 系统需要先安装ffmpeg，使用mac或者linux
# uv pip install requests
# uv pip install lxml
import requests
import os
import json
import re
from pathlib import Path
from lxml import etree

VIDEO_LIST = [
    ("BV1tz4y1Z7wr", "中国发展成就"),
    ("BV1PV411w7UX", "China's development achievements over the last three years"),
    ("BV1t6K8zFEnH", "打开数字之门，链接虚实空间，实现文化共建"),
]

# 输出目录（相对于项目根目录）
OUTPUT_DIR = Path(__file__).parent.parent / "video"
OUTPUT_DIR.mkdir(exist_ok=True)


def download_video(bv: str, title: str = None):
    """下载单个视频"""
    print(f"\n{'='*60}")
    print(f"开始下载: {bv}")
    if title:
        print(f"标题: {title}")
    print(f"{'='*60}\n")
    
    url = f"https://www.bilibili.com/video/{bv}"
    
    headers = {
        "user-agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36", 
        "referer": url
    }
    
    try:
        print(f"==> 正在获取 {bv} 的网页源代码...")
        res = requests.get(url, headers=headers)
        res.raise_for_status()
        
        print(f"==> 正在解析 {bv} 的网页源代码...")
        html = etree.HTML(res.text)
        
        # 尝试多种方式获取视频数据
        src_dict = None
        scripts = html.xpath('/html/head/script')
        
        for _, script in enumerate(scripts):
            script_text = script.text
            if script_text and 'window.__playinfo__' in script_text:
                match = re.search(r'window\.__playinfo__\s*=\s*({.+?});', script_text, re.DOTALL)
                if match:
                    try:
                        src_dict = json.loads(match.group(1))
                        break
                    except json.JSONDecodeError:
                        continue
        
        # 如果上面的方法失败，尝试原始方法
        if not src_dict:
            try:
                src = str(html.xpath('/html/head/script[4]/text()')[0])
                if src.startswith('window.__playinfo__'):
                    src = src[20:]
                    src_dict = json.loads(src)
            except (IndexError, json.JSONDecodeError, KeyError):
                pass
        
        if not src_dict or 'data' not in src_dict:
            raise ValueError(f"无法解析视频数据: {bv}")
        
        # 获取视频和音频地址
        print("==> 正在获取视频地址...")
        dash = src_dict['data'].get('dash', {})
        if not dash:
            raise ValueError(f"视频 {bv} 不支持dash格式")
        
        video_list = dash.get('video', [])
        audio_list = dash.get('audio', [])
        
        if not video_list or not audio_list:
            raise ValueError(f"无法获取视频或音频URL: {bv}")
        
        v_url = video_list[0].get('backup_url', [])
        if not v_url:
            v_url = video_list[0].get('base_url', '')
        else:
            v_url = v_url[0] if isinstance(v_url, list) else v_url
        
        a_url = audio_list[0].get('backup_url', [])
        if not a_url:
            a_url = audio_list[0].get('base_url', '')
        else:
            a_url = a_url[0] if isinstance(a_url, list) else a_url
        
        if not v_url or not a_url:
            raise ValueError(f"无法获取有效的视频或音频URL: {bv}")
        
        # 生成输出文件名
        if title:
            safe_title = re.sub(r'[<>:"/\\|?*]', '_', title)
            if len(safe_title) > 100:
                safe_title = safe_title[:100]
            filename = f"{bv}_{safe_title}.mp4"
        else:
            filename = f"{bv}.mp4"
        
        output_path = OUTPUT_DIR / filename
        
        # 如果文件已存在，跳过
        if output_path.exists():
            print(f"==> 文件已存在，跳过: {output_path}")
            return
        
        # 临时文件路径
        temp_video = OUTPUT_DIR / f"{bv}_temp_v.mp4"
        temp_audio = OUTPUT_DIR / f"{bv}_temp_a.mp3"
        
        # 下载音频
        print("==> 正在下载音频...")
        res = requests.get(a_url, headers=headers, stream=True)
        res.raise_for_status()
        with open(temp_audio, "wb") as f:
            total_size = int(res.headers.get('content-length', 0))
            downloaded = 0
            for chunk in res.iter_content(chunk_size=8192):
                if chunk:
                    f.write(chunk)
                    downloaded += len(chunk)
                    if total_size > 0:
                        percent = (downloaded / total_size) * 100
                        print(f"\r==> 音频下载进度: {percent:.1f}%", end='', flush=True)
            print()
        
        # 下载视频
        print("==> 正在下载视频...")
        res = requests.get(v_url, headers=headers, stream=True)
        res.raise_for_status()
        with open(temp_video, "wb") as f:
            total_size = int(res.headers.get('content-length', 0))
            downloaded = 0
            for chunk in res.iter_content(chunk_size=8192):
                if chunk:
                    f.write(chunk)
                    downloaded += len(chunk)
                    if total_size > 0:
                        percent = (downloaded / total_size) * 100
                        print(f"\r==> 视频下载进度: {percent:.1f}%", end='', flush=True)
            print()
        
        # 合并视频和音频
        print("==> 正在合并视频和音频...")
        cmd = f'ffmpeg -i "{temp_video}" -i "{temp_audio}" -c:v copy -c:a aac -strict experimental -y "{output_path}"'
        result = os.system(cmd)
        
        if result != 0:
            raise RuntimeError(f"ffmpeg合并失败: {bv}")
        
        # 删除临时文件
        print("==> 正在删除临时文件...")
        temp_video.unlink(missing_ok=True)
        temp_audio.unlink(missing_ok=True)
        
        print(f"==> 下载完成: {output_path}")
        
    except Exception as e:
        print(f"==> 下载失败 {bv}: {str(e)}")
        raise


def main():
    """主函数：批量下载视频"""
    print(f"\n开始批量下载，共 {len(VIDEO_LIST)} 个视频\n")
    
    success_count = 0
    fail_count = 0
    
    for i, (video_id, title) in enumerate(VIDEO_LIST, 1):
        try:
            print(f"\n[{i}/{len(VIDEO_LIST)}] 处理: {title}")
            download_video(video_id, title)
            success_count += 1
        except Exception as e:
            print(f"\n[{i}/{len(VIDEO_LIST)}] 失败: {title}")
            print(f"错误: {str(e)}")
            fail_count += 1
    
    print(f"\n{'='*60}")
    print("批量下载完成!")
    print(f"成功: {success_count} 个")
    print(f"失败: {fail_count} 个")
    print(f"{'='*60}\n")


if __name__ == "__main__":
    main()

