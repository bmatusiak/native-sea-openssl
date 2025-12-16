rm -rf ./rn-app
npx -y @react-native-community/cli init RNApp --version 0.81.5
mv RNApp rn-app
cd rn-app
rm -rf ./.bundle
rm -rf ./ios
rm -rf ./Gemfile
npm install ../../native-sea-openssl-package
rm -rf ./node_modules
rm -rf ./git
rm -rf ./tsconfig.json

rm -rf ./package-lock.json
# append to .gitigore
echo "package-lock.json" >> ./.gitignore
rm -rf ./App.tsx
rm -rf ./__tests__/App.test.tsx