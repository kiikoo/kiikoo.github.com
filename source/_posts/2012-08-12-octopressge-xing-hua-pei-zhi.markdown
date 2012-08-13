---
layout: post
title: "octopress个性化配置"
date: 2012-08-12 11:27
comments: true
categories: [学习分享]
tags: [octopress,博客]
---
一直想搭建个博客，之前在iteye，sina等上面杂乱的写过一些，但是始终没有坚持下来，也没怎么更新。最近[octopress](http://octopress.org)异常的火，我也忍不住用octopress+github搭建了自己的博客。折腾了几天，有了个雏形。
octoprees官方整理了一个使用octopress搭建博客[列表](https://github.com/imathis/octopress/wiki/Octopress-Sites)，我在这上面参考了不少，可以多去这些博客逛逛。

<!--more-->

* ###为octopress添加category列表

[参考blog](http://codemacro.com/2012/07/18/add-category-list-to-octopress/)

增加category_list插件

[category_list_tag.rb](https://github.com/kiikoo/kiikoo.github.com/blob/source/plugins/category_list_tag.rb)
    
增加aside

复制以下代码到source/_includes/asides/category_list.html。

    <section>
     <h1>Categories</h1>
     <ul id="categories">
       {% category_list %}
     </ul>
    </section>
    
配置侧边栏需要修改_config.yml文件，修改其default_asides项：

     default_asides: [asides/category_list.html, asides/recent_posts.html]


* ###为octopress添加tag_cloud

[参考blog](http://codemacro.com/2012/07/18/add-tag-to-octopress/)

首先到https://github.com/robbyedwards/octopress-tag-pages和https://github.com/robbyedwards/octopress-tag-cloudclone这两个项目的代码。这两个项目分别用于产生tag page和tag cloud。 针对这两个插件，需要手工复制一些文件到你的octopress目录。

* octopress-tag-pages

复制tag_generator.rb到/plugins目录；复制tag_index.html到/source/_layouts目录。需要注意的是，还需要复制tag_feed.xml到/source/_includes/custom/目录。这个官方文档里没提到，在我机器上rake generate时报错。其他文件就不需要复制了，都是些例子。

* octopress-tag-cloud

仅复制tag_cloud.rb到/plugins目录即可。但这仅仅只是为liquid添加了一个tag（非本文所提tag）。如果要在侧边导航里添加一个tag cloud，我们还需要手动添加aside。

复制以下代码到/source/_includes/custom/asides/tags.html。

    <section>
      <h1>Tags</h1>
      <ul class="tag-cloud">
        {% tag_cloud font-size: 90-210%, limit: 10, style: para %}
      </ul>
    </section>
    
注明：
     
     这一部分我在使用的时候一直会报错，
     Liquid error: comparison of Array with Array failed。
     原因还未定位到,
     后面我将{% tag_cloud font-size: 90-210%, limit: 10, style: para %}
     修改为{% tag_cloud font-size: 90-210%, style: para %}
     就没错误了。

最后，当然是在_config.xml的default_asides 中添加这个tag cloud到导航栏，例如：
 
     default_asides: [asides/category_list.html, asides/recent_posts.html, custom/asides/tags.html]
     
####在文章最后显示文章的tags：

将source/_layouts/page.html文件改为

[page.html](https://github.com/kiikoo/kiikoo.github.com/blob/source/source/_layouts/page.html)
      
####Archive页面中展示以下效果

     posted in 学习, 技术 tagged with python 
     
修改source/_includes/archive_post.html文件为

[archive_post.htm](https://github.com/kiikoo/kiikoo.github.com/blob/source/source/_includes/archive_post.html)
   
* ###为octopress添加评论功能

octopress默认支持disqus评论，只需注册disqus帐号，并将_config.yml文件中关于disqus配置打开
    
    isqus_short_name: yourAccount
	disqus_show_comment_count: true
		

