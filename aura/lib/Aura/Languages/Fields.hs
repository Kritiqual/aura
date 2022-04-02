{-# LANGUAGE LambdaCase #-}

{-# OPTIONS_HADDOCK prune #-}

-- |
-- Module    : Aura.Languages.Fields
-- Copyright : (c) Colin Woodbury, 2012 - 2021
-- License   : GPL3
-- Maintainer: Colin Woodbury <colin@fosskers.ca>
--
-- The various fields for @-Ai@ output.

module Aura.Languages.Fields where

import Aura.Types (Language(..))
import RIO (Text)

---

package :: Language -> Text
package = \case
    Japanese   -> "パッケージ"
    Polish     -> "Pakiet"
    Croatian   -> "Paket"
    Swedish    -> "Paket"
    German     -> "Paket"
    Turkish    -> "Paket"
    Spanish    -> "Paquete"
    Portuguese -> "Pacote"
    French     -> "Paquet"
    Russian    -> "Пакет"
    Italian    -> "Pacchetto"
    Serbian    -> "Пакет"
    Norwegian  -> "Pakke"
    Indonesia  -> "Paket"
    Esperanto  -> "Pakaĵo"
    Dutch      -> "Pakket"
    Romanian   -> "Pachet"
    Vietnamese -> "Gói"
    Czech      -> "Balíček"
    Korean     -> "패키지"
    _          -> "Package"

firstInstall :: Language -> Text
firstInstall = \case
    Japanese   -> "初インストール"
    Polish     -> "Pierwsza instalacja"
    Croatian   -> "Prva instalacija"
    Swedish    -> "Första installation"
    German     -> "Erste Installation"
    Turkish    -> "İlk Kurulum"
    Spanish    -> "Primera instalación"
    Portuguese -> "Primeira instalação"
    French     -> "Première installation"
    Russian    -> "Первая установка"
    Italian    -> "Prima installazione"
    Serbian    -> "Прва инсталација"
    Norwegian  -> "Første installasjon"
    Indonesia  -> "Versi sistem"
    Esperanto  -> "Unua Instalo"
    Dutch      -> "Eerste installatie"
    Romanian   -> "Prima instalare"
    Vietnamese -> "Cài đặt lần đầu"
    Czech      -> "První instalace"
    Korean     -> "최초 설치"
    _          -> "First Install"

upgrades :: Language -> Text
upgrades = \case
    Japanese   -> "アップグレード回数"
    Polish     -> "Aktualizacje"
    Croatian   -> "Nadogradnje"
    Swedish    -> "Uppgraderingar"
    German     -> "Aktualisierungen"
    Turkish    -> "Güncellemeler"
    Spanish    -> "Actualizaciones"
    Portuguese -> "Atualizações"
    French     -> "Mises à jours"
    Russian    -> "Обновления"
    Italian    -> "Aggiornamenti"
    Serbian    -> "Ажурирања"
    Norwegian  -> "Oppgraderinger"
    Indonesia  -> "Tingkatkan"
    Esperanto  -> "Noveldonoj"
    Dutch      -> "Opwaarderingen"
    Romanian   -> "Actualizări"
    Vietnamese -> "Cập nhật"
    Czech      -> "Aktualizace"
    Korean     -> "업그레이드 횟수"
    _          -> "Upgrades"

recentActions :: Language -> Text
recentActions = \case
    Japanese   -> "近況"
    Polish     -> "Ostatnie akcje"
    Croatian   -> "Nedavne radnje"
    Swedish    -> "Nyliga händelser"
    German     -> "Letzte Aktionen"
    Turkish    -> "Güncel Eylem"
    Spanish    -> "Acciones Recientes"
    Portuguese -> "Ações Recentes"
    French     -> "Actions récentes"
    Russian    -> "Недавние действия"
    Italian    -> "Azioni recenti"
    Serbian    -> "Недавне радње"
    Norwegian  -> "Nylige hendelser"
    Indonesia  -> "Aksi sekarang"
    Esperanto  -> "Ĵusaj Agoj"
    Dutch      -> "Onlangs uitgevoerde acties"
    Romanian   -> "Acțiuni Recente"
    Vietnamese -> "Hoạt động gần nhất"
    Czech      -> "Nedávné akce"
    Korean     -> "근황"
    _          -> "Recent Actions"

repository :: Language -> Text
repository = \case
    Japanese   -> "リポジトリ"
    Polish     -> "Repozytorium"
    Croatian   -> "Repozitorij"
    Swedish    -> "Repository"
    German     -> "Repository"
    Turkish    -> "Depo"
    Spanish    -> "Repositorio"
    Portuguese -> "Repositório"
    French     -> "Dépôt"
    Russian    -> "Репозиторий"
    Italian    -> "Repository"
    Serbian    -> "Ризница"
    Norwegian  -> "Depot"
    Indonesia  -> "Lumbung"
    Esperanto  -> "Deponejo"
    Dutch      -> "Pakketbron"
    Romanian   -> "Repertoriu"
    Czech      -> "Úložiště"
    Korean     -> "리포지토리"
    _          -> "Repository"

name :: Language -> Text
name = \case
    Japanese   -> "名前"
    Polish     -> "Nazwa"
    Croatian   -> "Ime"
    Swedish    -> "Namn"
    German     -> "Name"
    Turkish    -> "İsim"
    Spanish    -> "Nombre"
    Portuguese -> "Nome"
    French     -> "Nom"
    Russian    -> "Название"
    Italian    -> "Nome"
    Serbian    -> "Име"
    Norwegian  -> "Navn"
    Indonesia  -> "Nama"
    Esperanto  -> "Nomo"
    Dutch      -> "Naam"
    Romanian   -> "Nume"
    Vietnamese -> "Tên"
    Czech      -> "Název"
    Korean     -> "이름"
    _          -> "Name"

version :: Language -> Text
version = \case
    Japanese   -> "バージョン"
    Polish     -> "Wersja"
    Croatian   -> "Verzija"
    Swedish    -> "Version"
    German     -> "Version"
    Turkish    -> "Sürüm"
    Spanish    -> "Versión"
    Portuguese -> "Versão"
    French     -> "Version"
    Russian    -> "Версия"
    Italian    -> "Versione"
    Serbian    -> "Верзија"
    Norwegian  -> "Versjon"
    Indonesia  -> "Versi"
    Esperanto  -> "Versio"
    Dutch      -> "Versie"
    Romanian   -> "Versiune"
    Vietnamese -> "Phiên bản"
    Czech      -> "Verze"
    Korean     -> "버전"
    _          -> "Version"

aurStatus :: Language -> Text
aurStatus = \case
    Japanese   -> "パッケージ状態"
    Polish     -> "Status w AUR"
    Croatian   -> "AUR Stanje"
    German     -> "AUR-Status"
    Turkish    -> "AUR Durumu"
    Spanish    -> "Estado en AUR"
    Portuguese -> "Estado no AUR"
    French     -> "Statut de AUR"
    Russian    -> "Статус в AUR"
    Italian    -> "Stato nell'AUR"
    Serbian    -> "Статус у AUR-у"
    Norwegian  -> "AUR Status"
    Indonesia  -> "Status AUR"
    Esperanto  -> "Stato en AUR"
    Dutch      -> "AUR-status"
    Romanian   -> "Stare AUR"
    Vietnamese -> "Trạng thái AUR"
    Czech      -> "Stav AUR"
    Korean     -> "AUR 상태"
    _          -> "AUR Status"

-- NEEDS TRANSLATION
maintainer :: Language -> Text
maintainer = \case
    Japanese   -> "管理者"
    Spanish    -> "Mantenedor"
    Portuguese -> "Mantenedor"
    French     -> "Mainteneur"
    Turkish    -> "Sağlayıcı"
    Russian    -> "Ответственный"
    Italian    -> "Mantenitore"
    Norwegian  -> "Vedlikeholder"
    Indonesia  -> "Pemelihara"
    Esperanto  -> "Daŭriganto"
    Dutch      -> "Eigenaar"
    Romanian   -> "Întreținător"
    Czech      -> "Udržovatel"
    Korean     -> "관리자"
    _          -> "Maintainer"

projectUrl :: Language -> Text
projectUrl = \case
    Japanese   -> "プロジェクト"
    Polish     -> "URL Projektu"
    Croatian   -> "URL Projekta"
    Swedish    -> "Projekt URL"
    German     -> "Projekt-URL"
    Turkish    -> "Proje URL'si"
    Spanish    -> "URL del proyecto"
    Portuguese -> "URL do projeto"
    French     -> "URL du projet"
    Russian    -> "URL проекта"
    Italian    -> "URL del progetto"
    Serbian    -> "Страница пројекта"
    Norwegian  -> "Prosjekt-URL"
    Indonesia  -> "URL Proyek"
    Esperanto  -> "URL de Projekto"
    Dutch      -> "Project-url"
    Romanian   -> "URL al proiectului"
    Vietnamese -> "URL của Dự án"
    Czech      -> "Adresa URL projektu"
    Korean     -> "프로젝트 URL"
    _          -> "Project URL"

aurUrl :: Language -> Text
aurUrl = \case
    Japanese   -> "パッケージページ"
    Polish     -> "URL w AUR"
    German     -> "AUR-URL"
    Turkish    -> "AUR URL"
    Spanish    -> "URL de AUR"
    Portuguese -> "URL no AUR"
    French     -> "URL AUR"
    Russian    -> "URL в AUR"
    Italian    -> "URL nell'AUR"
    Serbian    -> "Страница у AUR-у"
    Norwegian  -> "AUR URL"
    Indonesia  -> "URL AUR"
    Esperanto  -> "URL en AUR"
    Dutch      -> "AUR-url"
    Romanian   -> "URL AUR"
    Vietnamese -> "URL của AUR"
    Czech      -> "URL pro AUR"
    Korean     -> "AUR URL"
    _          -> "AUR URL"

license :: Language -> Text
license = \case
    Japanese   -> "ライセンス"
    Polish     -> "Licencja"
    Croatian   -> "Licenca"
    Swedish    -> "Licens"
    German     -> "Lizenz"
    Turkish    -> "Lisans"
    Spanish    -> "Licencia"
    Portuguese -> "Licença"
    French     -> "Licence"
    Russian    -> "Лицензия"
    Italian    -> "Licenza"
    Serbian    -> "Лиценца"
    Norwegian  -> "Lisens"
    Indonesia  -> "Lisensi"
    Esperanto  -> "Permesilo"
    Dutch      -> "Licentie"
    Romanian   -> "Licență"
    Vietnamese -> "Bản quyền"
    Czech      -> "Licence"
    Korean     -> "라이센스"
    _          -> "License"

dependsOn :: Language -> Text
dependsOn = \case
    Japanese   -> "従属パッケージ"
    Polish     -> "Zależności"
    Croatian   -> "Zavisnosti"
    German     -> "Hängt ab von"
    Turkish    -> "Gerekler"
    Spanish    -> "Dependencias"
    Portuguese -> "Dependências"
    French     -> "Dépends de"
    Russian    -> "Зависит от"
    Italian    -> "Dipende da"
    Norwegian  -> "Er avhengig av"
    Indonesia  -> "Bergantung pada"
    Esperanto  -> "Dependi de"
    Dutch      -> "Afhankelijk van"
    Romanian   -> "Depinde de"
    Vietnamese -> "Phụ thuộc vào"
    Czech      -> "Závisí na"
    Korean     -> "종속 패키지"
    _          -> "Depends On"

buildDeps :: Language -> Text
buildDeps = \case
    Japanese   -> "作成時従属パ"
    German     -> "Build-Abhängigkeiten"
    Turkish    -> "İnşa Gerekleri"
    Spanish    -> "Dependencias de compilación"
    Portuguese -> "Dependências de compilação"
    French     -> "Dépendances de compilation"
    Russian    -> "Зависимости сборки"
    Italian    -> "Dipendenze di compilazione"
    Norwegian  -> "Byggavhengigheter"
    Indonesia  -> "Dependensi bangun"
    Esperanto  -> "Muntaj Dependecoj"
    Dutch      -> "Bouwafhankelijkheden"
    Romanian   -> "Dependențe de compilare"
    Czech      -> "Závislosti kompilace"
    Korean     -> "빌드 종속성"
    _          -> "Build Deps"

votes :: Language -> Text
votes = \case
    Japanese   -> "投票数"
    Polish     -> "Głosy"
    Croatian   -> "Glasovi"
    Swedish    -> "Röster"
    German     -> "Stimmen"
    Turkish    -> "Oylar"
    Spanish    -> "Votos"
    Portuguese -> "Votos"
    French     -> "Votes"
    Russian    -> "Голоса"
    Italian    -> "Voti"
    Serbian    -> "Гласови"
    Norwegian  -> "Stemmer"
    Indonesia  -> "Suara"
    Esperanto  -> "Balotiloj"
    Dutch      -> "Aantal stemmen"
    Romanian   -> "Voturi"
    Vietnamese -> "Bình chọn"
    Czech      -> "Hlasy"
    Korean     -> "투표"
    _          -> "Votes"

popularity :: Language -> Text
popularity = \case
    Japanese   -> "人気"
    Spanish    -> "Popularidad"
    Portuguese -> "Popularidade"
    Turkish    -> "Popülerlik"
    Italian    -> "Popolarità"
    Norwegian  -> "Popularitet"
    Esperanto  -> "Populareco"
    Dutch      -> "Populariteit"
    Romanian   -> "Popularitate"
    Vietnamese -> "Phổ biến"
    Czech      -> "Popularita"
    Korean     -> "인기"
    _          -> "Popularity"

description :: Language -> Text
description = \case
    Japanese   -> "概要"
    Polish     -> "Opis"
    Croatian   -> "Opis"
    Swedish    -> "Beskrivning"
    German     -> "Beschreibung"
    Turkish    -> "Tanım"
    Spanish    -> "Descripción"
    Portuguese -> "Descrição"
    French     -> "Description"
    Russian    -> "Описание"
    Italian    -> "Descrizione"
    Serbian    -> "Опис"
    Norwegian  -> "Beskrivelse"
    Indonesia  -> "Deskripsi"
    Esperanto  -> "Priskribo"
    Dutch      -> "Beschrijving"
    Romanian   -> "Descriere"
    Vietnamese -> "Mô tả"
    Czech      -> "Popis"
    Korean     -> "개요"
    _          -> "Description"
