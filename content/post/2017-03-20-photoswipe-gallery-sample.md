---
title: Photoswipe Gallery Sample
subtitle: Making a Gallery
date: 2017-03-20
author: Not me
tags: ["example", "photoswipe"]
---

Beautiful Hugo adds a few custom shortcodes created by [Li-Wen Yip](https://www.liwen.id.au/photoswipe/) and [Gert-Jan van den Berg](https://github.com/GjjvdBurg/HugoPhotoSwipe) for making galleries with [PhotoSwipe](http://photoswipe.com) .

{{< gallery >}}
  {{< figure thumb="-thumb" link="/img/hexagon.jpg" >}}
  {{< figure thumb="-thumb" link="/img/sphere.jpg" alt="Sphere" >}}
  {{< figure thumb="-thumb" link="/img/triangle.jpg" alt="Triangle" caption="This is a long comment about a triangle" >}}
{{< /gallery >}}
{{< pswp-init >}}

<!--more-->
## Example
The above gallery was created using the following shortcodes:
```
{{</* gallery */>}}
  {{</* figure thumb="-thumb" link="/img/hexagon.jpg" */>}}
  {{</* figure thumb="-thumb" link="/img/sphere.jpg" alt="Sphere" */>}}
  {{</* figure thumb="-thumb" link="/img/triangle.jpg" alt="Triangle" caption="This is a long comment about a triangle" */>}}
{{</* /gallery */>}}
{{</* pswp-init */>}}
```

## Usage
As described on the [GitHub](https://github.com/liwenyip/hugo-pswp) page:

* Call `{{</* pswp-init */>}}` **once** anywhere you want on each page where you want to use PhotoSwipe
* `{{</* figure src="image.jpg" */>}}` will use `image.jpg` for thumbnail and lightbox
* `{{</* figure src="thumb.jpg" link="image.jpg" */>}}` will use `thumb.jpg` for thumbnail and `image.jpg` for lightbox
* `{{</* figure thumb="-small" link="image.jpg" */>}}` will use `image-small.jpg` for thumbnail and `image.jpg` for lightbox
* `{{</* figure thumb="-small" link="image.jpg" size="1024x768 "*/>}}` will avoid needing to pre-load `image.jpg` to determine its size (optional)
* All the [features/parameters](https://gohugo.io/extras/shortcodes) of Hugo's built-in `figure` shortcode work as normal, i.e. src, link, title, caption, class, attr (attribution), attrlink, alt
* `{{</* figure src="image.jpg" class="pswp-ignore" */>}}` will be ignored by PhotoSwipe (if that's what you really want)
* enclose your figures in `{{</* gallery title="title of your gallery (optional)" */>}}` and `{{</* /gallery */>}}` to arrange your thumbnails inside a box
