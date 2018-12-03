rm -rf ./source
rm -rf ./themes/
rm -rf _config.yml 
git clone https://github.com/gotoco/blog
git clone https://github.com/wzpan/hexo-theme-freemind.git themes/freemind
mv ./blog/source/ ./
mv ./blog/themes/freemind/_config.yml  ./themes/freemind/
mv ./blog/_config.yml  ./
mv ./blog/.gitignore  ./
mv ./blog/deploy_hexo.sh ./
rm -rf ./blog
